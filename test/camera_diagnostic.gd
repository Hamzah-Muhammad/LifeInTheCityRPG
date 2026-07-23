extends Node
## One-off diagnostic: instantiates the REAL malik_bedroom.tscn (so real walls/
## furniture/collision layers are present, not an isolated player) and reads
## back the actual global transforms of the camera rig after physics settles,
## and whether SpringArm3D's collision avoidance shortened the arm (which
## would explain a camera collapsed down near the pivot = looks first-person).
## Run: godot --headless --path . res://test/camera_diagnostic.tscn

const BEDROOM_SCENE := "res://scenes/apartment/malik_bedroom.tscn"


func _ready() -> void:
	var bedroom: Node = (load(BEDROOM_SCENE) as PackedScene).instantiate()
	add_child(bedroom)

	for i in 15:
		await get_tree().physics_frame

	var player: Node3D = bedroom.get_node("Player")
	var pivot: Node3D = player.get_node("CameraPivot")
	var arm: SpringArm3D = pivot.get_node("SpringArm3D")
	var cam: Camera3D = arm.get_node("Camera3D")

	var player_forward: Vector3 = -player.global_transform.basis.z
	var cam_forward: Vector3 = -cam.global_transform.basis.z
	var cam_offset: Vector3 = cam.global_position - player.global_position

	print("== CAMERA DIAGNOSTIC (real bedroom scene) ==")
	print("player global_position = %s" % player.global_position)
	print("player forward (-basis.z) = %s" % player_forward)
	print("pivot global_position = %s" % pivot.global_position)
	print("configured spring_length = %f" % arm.spring_length)
	print("cam global_position = %s" % cam.global_position)
	print("cam offset from player = %s  (length=%f)" % [cam_offset, cam_offset.length()])
	print("cam forward (-basis.z) = %s" % cam_forward)
	print("dot(player_forward, cam_offset.normalized()) = %f  (negative = camera is BEHIND player)" % player_forward.dot(cam_offset.normalized()))
	print("dot(player_forward, cam_forward) = %f  (positive = camera looks the SAME way player faces)" % player_forward.dot(cam_forward))
	print("ACTUAL arm length in use (cam offset magnitude minus pivot's own 0.35/1.5 offset accounted for) — if far below 2.4, spring arm is self-colliding")

	get_tree().quit(0)
