# Godot 4 Boids Flocking Demo

A real-time implementation of Craig Reynolds' [Boids algorithm](https://www.red3d.com/cwr/boids/) in Godot 4. 150 agents exhibit emergent flocking behavior through three deceptively simple local rules.

## Demo

[![Boids Flocking Demo](https://img.youtube.com/vi/-riNYVJONNw/0.jpg)](https://youtu.be/-riNYVJONNw)

---

## Opening the Project

1. Install **Godot 4.3 or later** (GL Compatibility renderer) from [godotengine.org](https://godotengine.org/)
2. Launch Godot and click **Import**
3. Navigate to this folder and select **project.godot**
4. Click **Import & Edit**, then press **F5** (or the Play button) to run

> **Renderer note:** The project is configured for GL Compatibility (OpenGL). If you see a renderer mismatch warning, accept the prompt to switch — or change the renderer in **Project → Project Settings → Rendering → Renderer**.

---

## The Three Flocking Rules

Each boid only knows about neighbors within its **vision radius**. From these purely local interactions, complex global behavior emerges.

| Rule | What it does |
|------|-------------|
| **Separation** | Steer away from neighbors inside the personal-space zone (≈45% of vision radius). Weighted by inverse distance so extremely close neighbors push harder. |
| **Alignment** | Match the average *velocity direction* of all visible neighbors — the flock stays coherent in heading. |
| **Cohesion** | Steer toward the average *position* of all visible neighbors — the flock holds together spatially. |

Each force is scaled by its weight slider and accumulated every frame.

---

## HUD Controls

The left-side panel updates all parameters **in real-time** while the simulation runs.

| Slider | Effect | Default |
|--------|--------|---------|
| **Agents** | Number of boids (respawns on change) | 150 |
| **Vision** | Perception radius in pixels | 80 |
| **Separation** | Separation force multiplier | 1.50 |
| **Alignment** | Alignment force multiplier | 1.00 |
| **Cohesion** | Cohesion force multiplier | 1.00 |

**Reset Boids** — destroys all agents and respawns them at random positions.

### Interesting presets to try

- **High separation, low cohesion** → scattered individuals, almost no flocking
- **Low separation, high cohesion** → tight, dense balls that clump together
- **All weights equal, small vision** → multiple small independent flocks
- **Large vision radius** → entire population acts as one synchronized flock

---

## Visual Features

- **Arrow shape** — each boid is drawn as a filled triangle pointing in its direction of travel
- **Fading trail** — up to 18 historical positions rendered as shrinking, alpha-faded dots; the trail cleanly breaks when a boid wraps across a screen edge
- **Color shifting** — hue shifts from cool blue (slow / isolated) to warm orange (fast / crowded) using a blend of speed ratio and neighbor density

---

## Project Structure

```
project.godot   Godot 4 project config — 1280×720, GL Compatibility
Main.tscn       Root scene (single Node2D, everything else built in code)
Main.gd         Simulation manager — parameters, boid spawning, HUD
Boid.gd         Individual boid — flocking logic, wrapping, custom drawing
README.md       This file
```

---

## Technical Notes

- **O(n²) neighbor queries** — each boid checks every other boid every frame. This is fine for 150–300 agents on modern hardware; beyond ~400 you may want a spatial hash or quadtree.
- **Screen wrapping** uses `get_viewport_rect().size` dynamically, so changing the window size (if you re-enable resizing) works without code changes.
- Boid nodes are plain `Node2D` instances with `Boid.gd` attached via `set_script()` at runtime — no separate `.tscn` file needed per boid.
- The `sim` back-reference in `Boid.gd` is intentionally untyped to avoid a circular `preload` dependency (`Main.gd` preloads `Boid.gd`).
