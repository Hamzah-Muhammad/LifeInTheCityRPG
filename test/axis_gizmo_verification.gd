extends Node
## Verifies the debug axis gizmo (redesigned 2026-07-22 to be fixed to the
## map instead of attached to the player, after the user correctly pointed
## out a player-attached gizmo is useless for reading off map/furniture
## coordinates, which don't rotate with you) draws real Godot world axes,
## stays fixed regardless of what the player does, and is genuinely absent
## from the player's own node subtree - not just visually appearing fixed.
##
## Run: godot --headless --path . res://test/axis_gizmo_verification.tscn

const GIZMO_SCENE := "res://scenes/debug/debug_axis_gizmo.tscn"
const PLAYER_SCENE := "res://scenes/player/player.tscn"
const BEDROOM_SCENE := "res://scenes/apartment/malik_bedroom.tscn"
const GIZMO_ARM_LENGTH := 0.8
const SAFETY_MARGIN := 0.3


func _ready() -> void:
	SettingsManager.show_debug_axes = true
	var all_ok := true
	print("== AXIS GIZMO VERIFICATION ==")

	# --- Geometry check: tips render exactly where Godot's own transform
	# composition predicts, at an arbitrary placement - proves the arrows
	# are real world-axis-aligned geometry. ---
	var gizmo: Node3D = (load(GIZMO_SCENE) as PackedScene).instantiate()
	add_child(gizmo)
	gizmo.global_position = Vector3(12.0, 3.0, -8.0)
	var gizmo_transform_before: Transform3D = gizmo.global_transform

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

	# --- Fixed-to-the-map check: a player moving/rotating FAR away, as a
	# completely separate sibling node (not a parent/child relationship),
	# must have zero effect on the gizmo's transform. ---
	var player: CharacterBody3D = (load(PLAYER_SCENE) as PackedScene).instantiate()
	add_child(player)
	player.global_position = Vector3(50.0, 0.0, 50.0)
	player.rotation.y = deg_to_rad(123.0)
	await get_tree().physics_frame

	var gizmo_unaffected := gizmo.global_transform.is_equal_approx(gizmo_transform_before)
	all_ok = all_ok and gizmo_unaffected
	print("gizmo transform unaffected by an unrelated player moving/rotating: %s" % gizmo_unaffected)
	player.queue_free()
	gizmo.queue_free()

	# --- Confirm the real bedroom scene's gizmo is a sibling of Player, not
	# a descendant of it (the actual architectural fix, checked directly in
	# the real scene tree rather than inferred). ---
	var bedroom: Node = (load(BEDROOM_SCENE) as PackedScene).instantiate()
	add_child(bedroom)
	for i in 15:
		await get_tree().physics_frame
	var real_player: Node3D = bedroom.get_node("Player")
	var real_gizmo: Node3D = bedroom.get_node("DebugAxisGizmo")
	var gizmo_is_under_player := real_player.is_ancestor_of(real_gizmo)
	all_ok = all_ok and not gizmo_is_under_player
	print("gizmo is NOT nested under Player in the real scene: %s" % (not gizmo_is_under_player))

	# --- Camera-overlap check at the gizmo's actual fixed placement ---
	var pivot: Node3D = real_player.get_node("CameraPivot")
	var arm: SpringArm3D = pivot.get_node("SpringArm3D")
	var cam: Camera3D = arm.get_node("Camera3D")
	var cam_to_gizmo: float = cam.global_position.distance_to(real_gizmo.global_position)
	var closest_possible_approach: float = cam_to_gizmo - GIZMO_ARM_LENGTH
	print("camera distance from the gizmo's fixed position: %f" % cam_to_gizmo)
	print("closest any gizmo geometry gets to the camera: %f" % closest_possible_approach)
	var camera_clear := closest_possible_approach > SAFETY_MARGIN
	all_ok = all_ok and camera_clear
	print("camera stays clear of the gizmo (margin > %.2fm): %s" % [SAFETY_MARGIN, camera_clear])

	print("")
	print(
		(
			"AXIS GIZMO VERIFICATION: %s"
			% (
				"PASS - real world axes, fixed to the map, clear of camera"
				if all_ok
				else "FAIL"
			)
		)
	)
	get_tree().quit(0 if all_ok else 1)
