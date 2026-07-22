extends Node
## Autoload "SceneTransition" — moves Malik between scenes (apartment <-> street,
## subway <-> destination areas).
##
## go() swaps the active scene, then finds a Marker3D named `marker_name`
## somewhere in the new scene and snaps the player (found via the "player"
## group) onto it. Two process_frame waits give change_scene_to_file's
## deferred swap time to actually land before we go looking for nodes in it.
## Every real inter-scene travel path (front door, subway) routes through
## here, so this is also the single choke point for the autosave.

var _pending_marker: String = ""


func go(scene_path: String, marker_name: String) -> void:
	if scene_path == "":
		return
	_pending_marker = marker_name
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	_place_player()
	SaveManager.save_game()


func _place_player() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	var marker_name := _pending_marker
	_pending_marker = ""
	if player == null or marker_name == "":
		return
	var marker := get_tree().current_scene.find_child(marker_name, true, false) as Node3D
	if marker == null:
		push_warning("SceneTransition: no marker named '%s' in the new scene" % marker_name)
		return
	player.global_transform = marker.global_transform
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
