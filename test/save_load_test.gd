extends Node
## Headless smoke test for SaveManager's serialize/deserialize round trip.
## Run: godot --headless --path . res://test/save_load_test.tscn
## Backs up any real save file first and restores it afterward so this never
## clobbers an actual player's save. Exits 0 on pass, 1 on fail.

const BACKUP_PATH := "user://savegame_test_backup.json"


func _ready() -> void:
	var had_real_save := SaveManager.has_save()
	if had_real_save:
		DirAccess.rename_absolute(SaveManager.SAVE_PATH, BACKUP_PATH)

	var passed := _run_round_trip()

	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		DirAccess.remove_absolute(SaveManager.SAVE_PATH)
	if had_real_save:
		DirAccess.rename_absolute(BACKUP_PATH, SaveManager.SAVE_PATH)

	print("SAVE/LOAD TEST RESULT: %s" % ("PASS" if passed else "FAIL"))
	get_tree().quit(0 if passed else 1)


func _run_round_trip() -> bool:
	var fake_player := CharacterBody3D.new()
	fake_player.add_to_group("player")
	fake_player.add_child(Node3D.new())
	fake_player.get_child(0).name = "CameraPivot"
	add_child(fake_player)
	fake_player.global_position = Vector3(12.5, 0.0, -7.25)
	fake_player.rotation.y = 1.57
	(fake_player.get_node("CameraPivot") as Node3D).rotation.x = -0.4

	GameState.reset()
	GameState.player_name = "Zainab"
	GameState.player_gender = "female"
	GameState.adjust("rep", 3)
	GameState.adjust("cash", -10)
	GameState.set_flag("test_flag")

	SaveManager.save_game()
	if not SaveManager.has_save():
		print("FAIL: save_game() did not write a file")
		return false

	# Reset in-memory state, then apply the saved data back directly
	# (skips the scene-swap half of load_game(), which reuses the same
	# already-proven await pattern as SceneTransition.go()).
	GameState.reset()
	fake_player.global_position = Vector3.ZERO
	fake_player.rotation.y = 0.0

	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		print("FAIL: saved file did not parse back to a Dictionary")
		return false

	SaveManager._pending_load = parsed
	SaveManager._apply_pending_load()

	var ok := (
		GameState.player_name == "Zainab"
		and GameState.player_gender == "female"
		and GameState.rep == 3
		and GameState.cash == 30
		and GameState.has_flag("test_flag")
		and fake_player.global_position.is_equal_approx(Vector3(12.5, 0.0, -7.25))
		and is_equal_approx(fake_player.rotation.y, 1.57)
	)
	print("player_name=%s gender=%s rep=%d cash=%d pos=%s rot_y=%f" % [
		GameState.player_name, GameState.player_gender, GameState.rep, GameState.cash,
		fake_player.global_position, fake_player.rotation.y,
	])
	return ok
