extends Node2D
## Individual boid — implements Craig Reynolds' three-rule flocking algorithm.
##
## Each frame this node:
##   1. Queries sim.boids for neighbors within sim.vision_radius
##   2. Computes separation / alignment / cohesion steering forces
##   3. Integrates velocity, wraps around screen edges
##   4. Redraws itself as an arrow triangle with a fading dot trail

# Injected by Main.gd before add_child() so it's ready when _ready() fires.
# Left untyped to avoid a circular preload dependency (Main preloads Boid).
var sim

# ── Movement ──────────────────────────────────────────────────────────────────

var velocity: Vector2 = Vector2.ZERO

const MAX_SPEED := 150.0  # px/s — hard cap on velocity magnitude
const MAX_FORCE := 350.0  # steering force limit applied each delta
const MIN_SPEED :=  40.0  # prevents boids from fully stalling

# ── Visuals ───────────────────────────────────────────────────────────────────

## Ring buffer of past global positions used for the trail effect.
var _trail: Array[Vector2] = []
const TRAIL_LEN := 18

## Current body color, updated each frame by speed + crowd density.
var _color: Color = Color.CYAN

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Start with a random heading and a speed somewhere in the valid range
	var angle := randf() * TAU
	velocity = Vector2(cos(angle), sin(angle)) * randf_range(MIN_SPEED, MAX_SPEED)

func _process(delta: float) -> void:
	if sim == null:
		return

	var neighbors := _get_neighbors()

	# Accumulate the three steering forces, weighted by the HUD sliders
	var steer := Vector2.ZERO
	if not neighbors.is_empty():
		steer += _separation(neighbors) * sim.separation_weight
		steer += _alignment(neighbors)  * sim.alignment_weight
		steer += _cohesion(neighbors)   * sim.cohesion_weight

	velocity += steer * delta
	velocity = velocity.limit_length(MAX_SPEED)

	# Clamp to minimum speed so boids never float to a standstill
	if velocity.length() < MIN_SPEED:
		velocity = velocity.normalized() * MIN_SPEED

	position += velocity * delta
	_wrap_edges()

	# Prepend the current global position, then trim the oldest entry
	_trail.push_front(global_position)
	if _trail.size() > TRAIL_LEN:
		_trail.resize(TRAIL_LEN)

	# Color: cool-blue when slow/isolated → warm-orange when fast/crowded
	var speed_t := velocity.length() / MAX_SPEED
	var crowd_t := clampf(float(neighbors.size()) / 10.0, 0.0, 1.0)
	var hue     := lerpf(0.60, 0.07, speed_t * 0.55 + crowd_t * 0.45)
	_color = Color.from_hsv(hue, 0.85, 1.0)

	queue_redraw()

# ── Neighbor query ────────────────────────────────────────────────────────────

func _get_neighbors() -> Array:
	var result: Array = []
	var r_sq: float = sim.vision_radius * sim.vision_radius
	for b in sim.boids:
		if b != self and global_position.distance_squared_to(b.global_position) < r_sq:
			result.append(b)
	return result

# ── Three steering forces ─────────────────────────────────────────────────────

## Separation — push away from neighbors inside the inner personal-space zone.
## Weighting by 1/distance means very-close neighbors exert a stronger push.
func _separation(neighbors: Array) -> Vector2:
	var steer := Vector2.ZERO
	var sep_r: float = sim.vision_radius * 0.45  # personal-space zone = 45% of vision
	var count := 0
	for n in neighbors:
		var d := global_position.distance_to(n.global_position)
		if d < sep_r and d > 0.0:
			steer += (global_position - n.global_position).normalized() / d
			count += 1
	if count == 0:
		return Vector2.ZERO
	steer /= float(count)
	return (steer.normalized() * MAX_SPEED - velocity).limit_length(MAX_FORCE)

## Alignment — steer toward the average heading of all visible neighbors.
func _alignment(neighbors: Array) -> Vector2:
	var avg := Vector2.ZERO
	for n in neighbors:
		avg += n.velocity
	avg /= float(neighbors.size())
	return (avg.normalized() * MAX_SPEED - velocity).limit_length(MAX_FORCE)

## Cohesion — steer toward the average position of all visible neighbors.
func _cohesion(neighbors: Array) -> Vector2:
	var center := Vector2.ZERO
	for n in neighbors:
		center += n.global_position
	center /= float(neighbors.size())
	return ((center - global_position).normalized() * MAX_SPEED - velocity).limit_length(MAX_FORCE)

# ── Screen wrapping ───────────────────────────────────────────────────────────

func _wrap_edges() -> void:
	var vp := get_viewport_rect().size
	if   position.x > vp.x: position.x -= vp.x
	elif position.x < 0.0:  position.x += vp.x
	if   position.y > vp.y: position.y -= vp.y
	elif position.y < 0.0:  position.y += vp.y

# ── Rendering ─────────────────────────────────────────────────────────────────

func _draw() -> void:
	# Fading dot trail — break on wrap discontinuities (large position jumps)
	for i in _trail.size():
		if global_position.distance_to(_trail[i]) > 250.0:
			break  # boid crossed a screen edge; skip remaining trail points
		var t := 1.0 - float(i) / float(TRAIL_LEN)
		var c := Color(_color.r, _color.g, _color.b, t * t * 0.5)
		var r := lerpf(2.5, 0.3, float(i) / float(TRAIL_LEN))
		draw_circle(to_local(_trail[i]), r, c)

	# Arrow/triangle pointing in the direction of travel
	if velocity.length_squared() < 1.0:
		return

	var ang := velocity.angle()
	const SZ := 8.0
	var tip := Vector2(SZ * 1.6,  0.0       ).rotated(ang)
	var bl  := Vector2(-SZ * 0.7, +SZ * 0.55).rotated(ang)
	var br  := Vector2(-SZ * 0.7, -SZ * 0.55).rotated(ang)

	draw_colored_polygon([tip, bl, br], _color)

	# Bright tip accent for a subtle glow effect
	var hi := _color.lightened(0.5)
	hi.a = 0.85
	draw_circle(tip, 1.8, hi)
