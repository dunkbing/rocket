extends Node2D

## The rock scenes to pick from when spawning.
@export var rock_scenes: Array[PackedScene] = []
## How many rocks to spawn.
@export var count: int = 40
## Rectangular region (in world space) to scatter rocks within.
@export var spawn_region: Rect2 = Rect2(-2000, -2000, 4000, 4000)
## Random size range applied to each rock.
@export var min_scale: float = 0.18
@export var max_scale: float = 0.28
## Keep rocks at least this far from this node (e.g. the rocket) so they don't
## spawn on top of it. Leave unset to disable.
@export var keep_clear_of: Node2D
@export var keep_clear_radius: float = 300.0


func _ready() -> void:
    spawn_rocks()


func spawn_rocks() -> void:
    if rock_scenes.is_empty():
        push_warning("RockSpawner: no rock_scenes assigned.")
        return

    for i in count:
        var rock: Node2D = _pick_scene().instantiate()
        rock.position = _random_position()
        rock.rotation = randf() * TAU
        rock.scale = Vector2.ONE * randf_range(min_scale, max_scale)
        add_child(rock)


func _pick_scene() -> PackedScene:
    return rock_scenes[randi() % rock_scenes.size()]


func _random_position() -> Vector2:
    # Try a few times to land outside the keep-clear zone; give up gracefully.
    for _attempt in 16:
        var pos := Vector2(
            randf_range(spawn_region.position.x, spawn_region.end.x),
            randf_range(spawn_region.position.y, spawn_region.end.y),
        )
        if keep_clear_of == null:
            return pos
        if pos.distance_to(keep_clear_of.global_position) >= keep_clear_radius:
            return pos
    # Couldn't find a clear spot — just use the last candidate.
    return Vector2(
        randf_range(spawn_region.position.x, spawn_region.end.x),
        randf_range(spawn_region.position.y, spawn_region.end.y),
    )
