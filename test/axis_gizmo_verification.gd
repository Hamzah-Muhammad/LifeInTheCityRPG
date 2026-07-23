extends Node
## Proves the debug axis gizmo draws Godot's REAL world/local axes - the
## same coordinate system used everywhere else in the project (furniture
## Transform3D placement in malik_bedroom.tscn, the camera rig, and
## tools/generate_scene.gd's Basis.rotated(Vector3.UP, angle) math) - not
## an invented/arbitrary visual scheme.
##
## Method: instantiate the real player.tscn, rotate the player to a
## non-trivial, non-axis-aligned yaw (37 degrees) and move it to a
## non-trivial position, then compute where each gizmo tip SHOULD be in
## world space using nothing but Godot's own global_transform composition
## (Node3D global_transform = parent_global_transform * local_transform,
## which is what every StaticBody3D/furniture placement in the game
## already relies on) - then compare against the actual rendered
## MeshInstance3D's real global_position. If they match to float
## precision, the gizmo's geometry is provably using the real engine
## axes, not something separate.
##
## Run: godot --headless --path . res://test/axis_gizmo_verification.tscn

const PLAYER_SCENE := "res://scenes/player/player.tscn"


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
		["TipXPos", Vector3(1.5, 0, 0)],
		["TipXNeg", Vector3(-1.5, 0, 0)],
		["TipYPos", Vector3(0, 1.5, 0)],
		["TipYNeg", Vector3(0, -1.5, 0)],
		["TipZPos", Vector3(0, 0, 1.5)],
		["TipZNeg", Vector3(0, 0, -1.5)],
	]
	for check in checks:
		var node_name: String = check[0]
		var local_offset: Vector3 = check[1]
		var tip: Node3D = gizmo.get_node(node_name)
		# Independently computed expected world position, using nothing but
		# the gizmo's own global_transform composition (Godot's standard
		# parent*local rule - the same rule every furniture StaticBody3D in
		# the game relies on for its own placement).
		var expected: Vector3 = gizmo.global_transform * local_offset
		var actual: Vector3 = tip.global_position
		var matches := expected.is_equal_approx(actual)
		all_ok = all_ok and matches
		print("%-10s expected=%s  actual=%s  match=%s" % [node_name, expected, actual, matches])

	print("")
	print("Malik model forward direction (should point along player's -Z, per the")
	print("facing fix confirmed earlier): %s" % -player.global_transform.basis.z)
	print("")
	print("AXIS GIZMO VERIFICATION: %s" % ("PASS - uses real Godot world axes" if all_ok else "FAIL"))
	get_tree().quit(0 if all_ok else 1)
