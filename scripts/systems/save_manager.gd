extends Node
## Autoload "SaveManager" — single-slot autosave.
##
## Saves after every scene transition (SceneTransition.go() calls save_game()
## once the player's been placed on their arrival marker) so Load Game always
## resumes exactly where the player left off. Captures GameState (stats,
## flags, chosen name/gender) plus the player's scene, position, facing, and
## camera pitch.

const SAVE_PATH := "user://savegame.json"

var _pending_load: Dictionary = {}


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var pivot := player.get_node_or_null("CameraPivot")
	var data := {
		"scene_path": get_tree().current_scene.scene_file_path,
		"player_position": [player.global_position.x, player.global_position.y, player.global_position.z],
		"player_rotation_y": player.rotation.y,
		"camera_pitch": pivot.rotation.x if pivot != null else 0.0,
		"game_state": {
			"rep": GameState.rep,
			"heat": GameState.heat,
			"loyalty": GameState.loyalty,
			"cash": GameState.cash,
			"flags": GameState.flags,
			"player_name": GameState.player_name,
			"player_gender": GameState.player_gender,
		},
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: could not open '%s' for writing" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	if not has_save():
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: could not open '%s' for reading" % SAVE_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: '%s' is not valid save data" % SAVE_PATH)
		return
	_pending_load = parsed
	var scene_path := str(parsed.get("scene_path", ""))
	if scene_path == "":
		return
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	_apply_pending_load()


func _apply_pending_load() -> void:
	var data := _pending_load
	_pending_load = {}

	var gs: Dictionary = data.get("game_state", {})
	GameState.rep = int(gs.get("rep", 0))
	GameState.heat = int(gs.get("heat", 0))
	GameState.loyalty = int(gs.get("loyalty", 0))
	GameState.cash = int(gs.get("cash", 40))
	GameState.flags = gs.get("flags", {})
	GameState.player_name = str(gs.get("player_name", GameState.DEFAULT_NAME))
	GameState.player_gender = str(gs.get("player_gender", GameState.DEFAULT_GENDER))

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var pos: Array = data.get("player_position", [0.0, 0.0, 0.0])
	player.global_position = Vector3(pos[0], pos[1], pos[2])
	player.rotation.y = float(data.get("player_rotation_y", 0.0))
	var pivot := player.get_node_or_null("CameraPivot")
	if pivot != null:
		pivot.rotation.x = float(data.get("camera_pitch", 0.0))
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
