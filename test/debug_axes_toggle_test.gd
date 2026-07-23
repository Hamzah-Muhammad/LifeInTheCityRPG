extends Node
## Verifies the debug axis gizmo's visibility actually follows
## SettingsManager.show_debug_axes, both ways. Exit 0 on pass, 1 on fail.
## Run: godot --headless --path . res://test/debug_axes_toggle_test.tscn

const PLAYER_SCENE := "res://scenes/player/player.tscn"


func _ready() -> void:
	SettingsManager.show_debug_axes = true
	var player_on: Node = (load(PLAYER_SCENE) as PackedScene).instantiate()
	add_child(player_on)
	var gizmo_on: Node3D = player_on.get_node("DebugAxisGizmo")
	var visible_when_on := gizmo_on.visible
	player_on.queue_free()

	SettingsManager.show_debug_axes = false
	var player_off: Node = (load(PLAYER_SCENE) as PackedScene).instantiate()
	add_child(player_off)
	var gizmo_off: Node3D = player_off.get_node("DebugAxisGizmo")
	var visible_when_off := gizmo_off.visible

	print("gizmo visible when setting=true:  %s" % visible_when_on)
	print("gizmo visible when setting=false: %s" % visible_when_off)

	var passed := visible_when_on == true and visible_when_off == false
	print("DEBUG AXES TOGGLE TEST: %s" % ("PASS" if passed else "FAIL"))
	get_tree().quit(0 if passed else 1)
