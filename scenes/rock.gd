extends StaticBody2D

## Particle explosion spawned when this rock is destroyed.
@export var explosion_scene: PackedScene

var _exploded: bool = false


func _ready() -> void:
    # The rocket looks for this group to know what it can destroy.
    add_to_group("rocks")


## Called by the rocket when it hits this rock.
func explode() -> void:
    if _exploded:
        return
    _exploded = true
    # Defer: we're inside a physics collision callback, so we can't change the
    # scene tree right now.
    _do_explode.call_deferred()


func _do_explode() -> void:
    if explosion_scene:
        var fx: Node2D = explosion_scene.instantiate()
        fx.global_position = global_position
        # Add to the scene root so the effect outlives this rock.
        get_tree().current_scene.add_child(fx)
    queue_free()
