extends CharacterBody3D
## Malik's third-person controller.
## WASD moves relative to facing, mouse orbits (X turns the body, Y pitches the
## camera arm), Shift sprints, E interacts with the nearest Interactable in
## range, Esc opens the pause menu. Movement/interact freeze while dialogue,
## station-select, or the pause menu is active.

signal interact_target_changed(prompt: String)

const WALK_SPEED := 3.2
const SPRINT_SPEED := 5.5
const GRAVITY := 18.0
const PITCH_MIN := -1.1
const PITCH_MAX := 0.5

const ANIM_BLEND := 0.2

@onready var _pivot: Node3D = $CameraPivot
@onready var _anim: AnimationPlayer = $Malik/Model/AnimationPlayer

var _nearest: Interactable = null


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_anim.play("Idle", ANIM_BLEND)


func _unhandled_input(event: InputEvent) -> void:
	if DialogueManager.active or StationManager.active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sensitivity := (
			SettingsManager.BASE_MOUSE_SENSITIVITY * SettingsManager.mouse_sensitivity_multiplier
		)
		rotate_y(-event.relative.x * sensitivity)
		_pivot.rotation.x = clampf(
			_pivot.rotation.x - event.relative.y * sensitivity, PITCH_MIN, PITCH_MAX
		)
	elif event.is_action_pressed("interact") and _nearest != null and not PauseManager.active:
		_nearest.interact()
	elif event.is_action_pressed("ui_cancel"):
		PauseManager.toggle()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input_dir := Vector2.ZERO
	if not DialogueManager.active and not StationManager.active and not PauseManager.active:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()
	_update_nearest_interactable()
	_update_animation(speed)


func _update_animation(speed: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var target := "Idle"
	if horizontal_speed > 0.1:
		target = "Run" if is_equal_approx(speed, SPRINT_SPEED) else "Walk"
	if _anim.current_animation != target:
		_anim.play(target, ANIM_BLEND)


func _update_nearest_interactable() -> void:
	var best: Interactable = null
	var best_dist := INF
	for area in $InteractionSensor.get_overlapping_areas():
		if area is Interactable:
			var dist := global_position.distance_squared_to(area.global_position)
			if dist < best_dist:
				best_dist = dist
				best = area
	if best != _nearest:
		_nearest = best
		interact_target_changed.emit(_nearest.prompt if _nearest != null else "")
