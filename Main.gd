extends Node2D
## Main simulation controller.
## Holds all tunable parameters (read by Boid.gd each frame), manages the
## boid population, and constructs the on-screen HUD entirely in code.

# ── Parameters exposed to boids ───────────────────────────────────────────────

var boid_count: int        = 150   # total active agents
var vision_radius: float   = 80.0  # neighbor perception radius (px)
var separation_weight: float = 1.5 # scale of the separation steering force
var alignment_weight: float  = 1.0 # scale of the alignment steering force
var cohesion_weight: float   = 1.0 # scale of the cohesion steering force

# ── Internals ─────────────────────────────────────────────────────────────────

## All living boid nodes; each boid reads this to find its neighbors.
var boids: Array = []

const BoidScript := preload("res://Boid.gd")

# HUD labels updated by slider callbacks so they show live values
var _lbl_count:  Label
var _lbl_vision: Label
var _lbl_sep:    Label
var _lbl_ali:    Label
var _lbl_coh:    Label

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_hud()
	_spawn_boids()

# Dark background — draw commands persist each frame without queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size),
			Color(0.04, 0.04, 0.12, 1.0))

# ── Boid management ───────────────────────────────────────────────────────────

## Destroy all existing boids, then spawn boid_count new ones at random positions.
func _spawn_boids() -> void:
	for b in boids:
		b.queue_free()
	boids.clear()

	var vp := get_viewport_rect().size
	for _i in boid_count:
		var b := Node2D.new()
		b.set_script(BoidScript)
		b.position = Vector2(randf() * vp.x, randf() * vp.y)
		# Set sim reference before add_child so it's ready when _ready() fires
		b.sim = self
		add_child(b)
		boids.append(b)

# ── HUD construction ──────────────────────────────────────────────────────────

func _build_hud() -> void:
	# CanvasLayer renders above the boid world, unaffected by any world transform
	var hud := CanvasLayer.new()
	add_child(hud)

	var panel := PanelContainer.new()
	panel.position = Vector2(10, 10)
	panel.custom_minimum_size = Vector2(245, 0)
	hud.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "BOIDS SIMULATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	# One label + slider per tunable parameter
	_lbl_count  = _add_slider(vbox, "Agents: 150",       boid_count,         10,  400,  1.0)
	_lbl_vision = _add_slider(vbox, "Vision: 80",        vision_radius,      20,  200,  5.0)
	_lbl_sep    = _add_slider(vbox, "Separation: 1.50",  separation_weight,  0.0, 4.0,  0.05)
	_lbl_ali    = _add_slider(vbox, "Alignment: 1.00",   alignment_weight,   0.0, 4.0,  0.05)
	_lbl_coh    = _add_slider(vbox, "Cohesion: 1.00",    cohesion_weight,    0.0, 4.0,  0.05)

	# Collect sliders in insertion order and wire up callbacks
	var sliders: Array = []
	for child in vbox.get_children():
		if child is HSlider:
			sliders.append(child)
	sliders[0].value_changed.connect(_on_count_changed)
	sliders[1].value_changed.connect(_on_vision_changed)
	sliders[2].value_changed.connect(_on_sep_changed)
	sliders[3].value_changed.connect(_on_ali_changed)
	sliders[4].value_changed.connect(_on_coh_changed)

	vbox.add_child(HSeparator.new())

	var btn := Button.new()
	btn.text = "Reset Boids"
	btn.pressed.connect(_spawn_boids)
	vbox.add_child(btn)

	var hint := Label.new()
	hint.text = "Drag sliders to tune\nflocking in real-time"
	hint.add_theme_font_size_override("font_size", 10)
	hint.modulate = Color(0.75, 0.75, 0.75)
	vbox.add_child(hint)

## Appends a value label and HSlider to parent; returns the label.
func _add_slider(parent: VBoxContainer, label_text: String,
		default_val: float, min_v: float, max_v: float, step: float) -> Label:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 12)
	parent.add_child(lbl)

	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step      = step
	s.value     = default_val
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(s)

	return lbl

# ── Slider callbacks ──────────────────────────────────────────────────────────

func _on_count_changed(val: float) -> void:
	boid_count = int(val)
	_lbl_count.text = "Agents: %d" % boid_count
	_spawn_boids()

func _on_vision_changed(val: float) -> void:
	vision_radius = val
	_lbl_vision.text = "Vision: %.0f" % val

func _on_sep_changed(val: float) -> void:
	separation_weight = val
	_lbl_sep.text = "Separation: %.2f" % val

func _on_ali_changed(val: float) -> void:
	alignment_weight = val
	_lbl_ali.text = "Alignment: %.2f" % val

func _on_coh_changed(val: float) -> void:
	cohesion_weight = val
	_lbl_coh.text = "Cohesion: %.2f" % val
