extends RigidBody2D

## How hard the rocket launches. The drag distance (in pixels) is multiplied
## by this to get the launch speed.
@export var power: float = 8.0
## Cap on launch speed so a huge drag doesn't fling it off-screen.
@export var max_launch_speed: float = 1500.0
## How many dots to draw in the trajectory preview (keep it small = short line).
@export var trajectory_points: int = 8
## Seconds between each simulated trajectory dot.
@export var trajectory_step: float = 0.05
## Radius of the dot nearest the rocket.
@export var dot_start_radius: float = 6.0
## Radius of the farthest dot (dots shrink from start to end).
@export var dot_end_radius: float = 1.0
## Color of the trajectory dots.
@export var dot_color: Color = Color(1, 1, 1, 0.8)

var _aiming: bool = false
var _drag_start: Vector2 = Vector2.ZERO
var _launched: bool = false
## Trajectory dot positions in the rocket's local space.
var _dots: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
    # Rocket sits still until launched.
    freeze = true
    _clear_trajectory()
    # Report contacts so we can blow up rocks we hit.
    contact_monitor = true
    max_contacts_reported = 4
    body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
    # Rocks add themselves to the "rocks" group in their _ready().
    if body.is_in_group("rocks") and body.has_method("explode"):
        body.explode()


func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            # Start a drag from anywhere on screen — the launch direction comes
            # from the drag, not from where you press, so it always works.
            _start_aim()
        elif _aiming:
            _aiming = false
            _launch()

    elif event is InputEventMouseMotion and _aiming:
        var velocity: Vector2 = _launch_velocity()
        _update_trajectory(velocity)
        # Point the rocket where it's about to shoot while you aim.
        if velocity.length() > 0.0:
            rotation = velocity.angle() + PI / 2.0


## Begin a new aim, stopping the rocket wherever it currently is.
func _start_aim() -> void:
    _aiming = true
    _launched = false
    _drag_start = get_global_mouse_position()
    # Halt any current motion and hold the rocket still while aiming.
    freeze = true
    linear_velocity = Vector2.ZERO
    angular_velocity = 0.0


## Velocity the rocket will get if launched right now.
## Drag BEHIND the rocket -> it shoots the OPPOSITE way (slingshot feel).
func _launch_velocity() -> Vector2:
    var drag: Vector2 = _drag_start - get_global_mouse_position()
    var velocity: Vector2 = drag * power
    if velocity.length() > max_launch_speed:
        velocity = velocity.normalized() * max_launch_speed
    return velocity


func _launch() -> void:
    var velocity: Vector2 = _launch_velocity()
    _clear_trajectory()
    _launched = true
    freeze = false
    linear_velocity = velocity


# While flying, keep the nose pointed along the current velocity so the rocket
# follows its arc instead of staying at a fixed angle.
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
    if not _launched:
        return
    var velocity: Vector2 = state.linear_velocity
    if velocity.length() > 1.0:
        var xform := state.transform
        xform = Transform2D(velocity.angle() + PI / 2.0, xform.origin)
        state.transform = xform
        state.angular_velocity = 0.0


## Simulate where the rocket will travel and store dots along that arc.
func _update_trajectory(velocity: Vector2) -> void:
    _dots.clear()
    var gravity: Vector2 = (
        ProjectSettings.get_setting("physics/2d/default_gravity_vector")
        * ProjectSettings.get_setting("physics/2d/default_gravity")
        * gravity_scale
    )
    var pos: Vector2 = global_position  # simulate in world space (gravity is world-space)
    var vel: Vector2 = velocity
    for i in trajectory_points:
        # Convert each world-space point into the rocket's (rotated) local
        # space so _draw() places the dots along the true flight arc.
        _dots.append(to_local(pos))
        vel += gravity * trajectory_step
        pos += vel * trajectory_step
    queue_redraw()


func _clear_trajectory() -> void:
    _dots.clear()
    queue_redraw()


# Draw the trajectory as dots that shrink with distance from the rocket.
func _draw() -> void:
    var count: int = _dots.size()
    for i in count:
        var t: float = float(i) / float(maxi(count - 1, 1))
        var radius: float = lerpf(dot_start_radius, dot_end_radius, t)
        draw_circle(_dots[i], radius, dot_color)
