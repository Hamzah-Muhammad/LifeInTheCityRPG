extends Node
## Proves the debug axis gizmo draws Godot's REAL world/local axes - the
## same coordinate system used everywhere else in the project (furniture
## Transform3D placement in malik_bedroom.tscn, the camera rig, and
## tools/generate_scene.gd's Basis.rotated(Vector3.UP, angle) math) - not
## an invented/arbitrary visual scheme.
##
## Also checks the gizmo's overall radius against the actual camera
## distance (from the real bedroom scene) to catch the class of bug where
## the gizmo's arms reach far enough to overlap the camera itself (found
## 2026-07-22: original 1.5m-radius gizmo nearly touched a ~1.49m-away
## camera - fixed by shrinking to 0.8m radius, verified here so it can't
## silently regress).
##
## Run: godot --headless --path . res://test/axis_gizmo_verification.tscn

const PLAYER_SCENE := "res://scenes/player/player.tscn"
const BEDROOM_SCENE := "res://scenes/apartment/malik_bedroom.tscn"
const GIZMO_ARM_LENGTH := 0.8
const SAFETY_MARGIN := 0.3


func _ready() -> void:
	SettingsManager.show_debug_axes = true
	var player: Node3D = (load(PLAYER_SCENE) as PackedScene).instantiate()
	add_child(player)

	# Non-trivial position + non-axis-aligned yaw, so this can't pass by
	# accident (e.g. if X/Z were silently swapped, a 0-degree test might
	# still look right).
	player.global_position = Vector3(12.0, 0.0, -8.0)
	player.rotation.y = deg_to_rad(37.0)

	var gizmo: Node3D = player.get_node("DebugAxisGizmo")

	print("== AXIS GIZMO VERIFICATION ==")
	print("player.global_transform.basis = %s" % player.global_transform.basis)
	print("gizmo.global_transform.basis  = %s" % gizmo.global_transform.basis)
	var basis_matches := player.global_transform.basis.is_equal_approx(gizmo.global_transform.basis)
	print("gizmo basis matches player basis exactly (no hidden extra rotation): %s" % basis_matches)
	print("")

	var all_ok := basis_matches
	var checks := [
		["TipXPos", Vector3(GIZMO_ARM_LENGTH, 0, 0)],
		["TipXNeg", Vector3(-GIZMO_ARM_LENGTH, 0, 0)],
		["TipYPos", Vector3(0, GIZMO_ARM_LENGTH, 0)],
		["TipYNeg", Vector3(0, -GIZMO_ARM_LENGTH, 0)],
		["TipZPos", Vector3(0, 0, GIZMO_ARM_LENGTH)],
		["TipZNeg", Vector3(0, 0, -GIZMO_ARM_LENGTH)],
	]
	for check in checks:
		var node_name: String = check[0]
		var local_offset: Vector3 = check[1]
		var tip: Node3D = gizmo.get_node(node_name)
		var expected: Vector3 = gizmo.global_transform * local_offset
		var actual: Vector3 = tip.global_position
		var matches := expected.is_equal_approx(actual)
		all_ok = all_ok and matches
		print("%-10s expected=%s  actual=%s  match=%s" % [node_name, expected, actual, matches])

	print("")
	print("Malik model forward direction (should point along player's -Z, per the")
	print("facing fix confirmed earlier): %s" % -player.global_transform.basis.z)
	player.queue_free()

	# --- Camera-overlap check, against the real bedroom scene ---
	print("")
	print("-- camera-overlap check (real bedroom scene) --")
	var bedroom: Node = (load(BEDROOM_SCENE) as PackedScene).instantiate()
	add_child(bedroom)
	for i in 15:
		await get_tree().physics_frame
	var real_player: Node3D = bedroom.get_node("Player")
	var pivot: Node3D = real_player.get_node("CameraPivot")
	var arm: SpringArm3D = pivot.get_node("SpringArm3D")
	var cam: Camera3D = arm.get_node("Camera3D")
	var real_gizmo: Node3D = real_player.get_node("DebugAxisGizmo")
	var cam_to_gizmo_center: float = cam.global_position.distance_to(real_gizmo.global_position)
	var closest_possible_approach: float = cam_to_gizmo_center - GIZMO_ARM_LENGTH
	print("camera distance from gizmo center: %f" % cam_to_gizmo_center)
	print("gizmo arm length: %f" % GIZMO_ARM_LENGTH)
	print("closest any gizmo geometry gets to the camera: %f" % closest_possible_approach)
	var camera_clear := closest_possible_approach > SAFETY_MARGIN
	print("camera stays clear of the gizmo (margin > %.2fm): %s" % [SAFETY_MARGIN, camera_clear])
	all_ok = all_ok and camera_clear

	print("")
	print("AXIS GIZMO VERIFICATION: %s" % ("PASS - uses real Godot world axes, sized clear of the camera" if all_ok else "FAIL"))
	get_tree().quit(0 if all_ok else 1)
