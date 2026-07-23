extends Node
## Verifies the debug axis gizmo's own visibility follows
## SettingsManager.show_debug_axes. Redesigned 2026-07-22: the gizmo now
## manages its own visibility in _ready() (see debug_axis_gizmo.gd) since
## it's fixed to the map rather than a child of the player, so this tests
## the gizmo scene directly instead of going through player.tscn.
## Exit 0 on pass, 1 on fail.
## Run: godot --headless --path . res://test/debug_axes_toggle_test.tscn

const GIZMO_SCENE := "res://scenes/debug/debug_axis_gizmo.tscn"


func _ready() -> void:
	SettingsManager.show_debug_axes = true
	var gizmo_on: Node3D = (load(GIZMO_SCENE) as PackedScene).instantiate()
	add_child(gizmo_on)
	var visible_when_on := gizmo_on.visible
	gizmo_on.queue_free()

	SettingsManager.show_debug_axes = false
	var gizmo_off: Node3D = (load(GIZMO_SCENE) as PackedScene).instantiate()
	add_child(gizmo_off)
	var visible_when_off := gizmo_off.visible

	print("gizmo visible when setting=true:  %s" % visible_when_on)
	print("gizmo visible when setting=false: %s" % visible_when_off)

	var passed := visible_when_on == true and visible_when_off == false
	print("DEBUG AXES TOGGLE TEST: %s" % ("PASS" if passed else "FAIL"))
	get_tree().quit(0 if passed else 1)
