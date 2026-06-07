# CLAUDE.md

Guidance for working in this repository.

## Project

A 2D **Godot 4.6** mobile game. The player slingshots a rocket (drag-to-aim, release
to launch) at rocks scattered around the world. Renderer is **Forward Plus** (see
`project.godot`); for mobile builds this should move to the Mobile/Compatibility
renderer.

## Working conventions

- **Never edit `.tscn` / `.tres` scene files directly.** The user wants to do all
  scene/node/Inspector changes themselves in the Godot editor. When a change needs a
  scene edit, give **step-by-step UI instructions** (which node, which Inspector
  property, what value) instead of editing the file. Writing/editing **`.gd` script
  files is fine.**
- GDScript in this project is indented with **4 spaces** (an editor linter enforces
  this), not tabs — match it when editing.
- Touch input works for free: Godot's *Emulate Mouse From Touch* (on by default) turns
  taps/drags into the `InputEventMouseButton` / `InputEventMouseMotion` events the
  scripts already handle. No touch-specific code is needed.

## Layout

- `scenes/` — all scenes and scripts (this project keeps `.gd` next to its `.tscn`).
- `assets/` — sprites (`rocket.png`, `rock1/2.png`, `death_rock*`, `gold.png`).
- `project.godot` — main scene is `scenes/main.tscn`.

## Scenes & scripts

- **`main.tscn`** (`Node2D` root) — the game scene. Contains:
  - `Rocket` (instance of `rocket.tscn`)
  - `Camera2D` running `follow_camera.gd`, with `target` → the Rocket
  - `RockSpawner` (`Node2D`) running `rock_spawner.gd`, with `rock_scenes` → [rock_1, rock_2]
- **`rocket.tscn`** + **`rocket.gd`** (`RigidBody2D`) — the slingshot rocket.
- **`rock_1.tscn` / `rock_2.tscn`** (`StaticBody2D` + `CollisionPolygon2D`) — rocks.
  Rocks are on **collision layer 2** (`rocks`).
- **`follow_camera.gd`** (`Camera2D`) — follows `target`'s position only (not
  rotation) each `_physics_process` so the view never spins with the rocket.
- **`rock_spawner.gd`** (`Node2D`) — on `_ready`, spawns `count` rocks at random
  positions within `spawn_region`, with random rotation and a uniform random scale in
  `[min_scale, max_scale]`. `keep_clear_of` + `keep_clear_radius` stop rocks spawning
  on top of a node (e.g. the rocket). `spawn_rocks()` is public for re-spawning.

## Rocket mechanic (`rocket.gd`)

- The body is `freeze`d until launched. Drag is read in `_input` (not
  `_unhandled_input`, so nothing can swallow it).
- **Press anywhere** starts an aim (`_start_aim`): it stops the rocket where it is so
  you can re-grab and re-shoot a flying/landed rocket. Launch direction comes from the
  **drag vector**, not the press location — so dragging always works.
- Drag **behind** the rocket → it shoots the **opposite** way (`_launch_velocity` =
  `(_drag_start - mouse) * power`, capped at `max_launch_speed`).
- While aiming, a **shrinking-dot trajectory** is drawn in `_draw()`. Points are
  simulated in world space (gravity-aware) then converted with `to_local()` so the arc
  stays correct while the rocket rotates to aim. Tunable via `trajectory_points`,
  `trajectory_step`, `dot_start_radius`, `dot_end_radius`, `dot_color`.
- While flying, `_integrate_forces` re-points the nose along the current velocity each
  physics frame so the rocket follows its arc. Sprite faces **up** at rotation 0, so
  the aim/flight rotation uses `velocity.angle() + PI/2`.

## Running

Open the project in Godot and press **F5** (run main scene) or **F6** (run current
scene). There is no command-line build/test setup in this repo.
