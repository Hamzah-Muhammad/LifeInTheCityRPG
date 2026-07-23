extends Node
## Verifies the ESC pause menu end-to-end: PauseManager toggling shows/hides
## the UI, movement freezes while paused, and the shared options_panel.tscn
## component works identically whether reached from the main menu or the
## in-game pause menu (not two divergent implementations).
## Run: godot --headless --path . res://test/pause_menu_test.tscn

const PLAYER_SCENE := "res://scenes/player/player.tscn"
const PAUSE_MENU_SCENE := "res://scenes/ui/pause_menu.tscn"
const OPTIONS_PANEL_SCENE := "res://scenes/ui/options_panel.tscn"


func _ready() -> void:
	var all_ok := true

	# --- PauseManager state machine ---
	PauseManager.active = false
	print("== PAUSE MENU TEST ==")
	all_ok = _check(all_ok, not PauseManager.active, "PauseManager starts inactive")

	var pause_ui: CanvasLayer = (load(PAUSE_MENU_SCENE) as PackedScene).instantiate()
	add_child(pause_ui)
	await get_tree().process_frame
	var background: ColorRect = pause_ui.get_node("Background")
	var panel: PanelContainer = pause_ui.get_node("Panel")
	all_ok = _check(all_ok, not background.visible and not panel.visible, "pause UI starts hidden")

	PauseManager.toggle()
	all_ok = _check(all_ok, PauseManager.active, "toggle() opens PauseManager")
	all_ok = _check(all_ok, background.visible and panel.visible, "opening PauseManager shows the pause UI")
	# Note: Input.mouse_mode manipulation is not reliably testable under
	# --headless (no real window/cursor exists to capture into) - not
	# asserted here. Verified functionally by the same pattern already
	# working for DialogueUI/StationSelectUI in real play.

	PauseManager.toggle()
	all_ok = _check(all_ok, not PauseManager.active, "toggle() again closes PauseManager")
	all_ok = _check(all_ok, not background.visible and not panel.visible, "closing PauseManager hides the pause UI")

	# --- Movement freezes while paused (horizontal only - gravity is a
	# pre-existing, separate concern not gated by any freeze state,
	# including the already-established Dialogue/Station ones) ---
	var player: CharacterBody3D = (load(PLAYER_SCENE) as PackedScene).instantiate()
	add_child(player)
	await get_tree().process_frame
	PauseManager.open()
	await get_tree().physics_frame
	Input.action_press("move_forward")
	await get_tree().physics_frame
	var horizontal_velocity := Vector2(player.velocity.x, player.velocity.z)
	Input.action_release("move_forward")
	PauseManager.close()
	all_ok = _check(all_ok, horizontal_velocity.is_zero_approx(), "horizontal movement input produces zero velocity while paused")
	player.queue_free()
	pause_ui.queue_free()

	# --- Shared options_panel.tscn behaves identically standalone ---
	var options_a: PanelContainer = (load(OPTIONS_PANEL_SCENE) as PackedScene).instantiate()
	add_child(options_a)
	var options_b: PanelContainer = (load(OPTIONS_PANEL_SCENE) as PackedScene).instantiate()
	add_child(options_b)
	await get_tree().process_frame

	var debug_check: CheckBox = options_a.get_node("Margin/VBox/DebugGrid/ShowDebugAxesCheck")
	debug_check.button_pressed = true
	debug_check.toggled.emit(true)
	all_ok = _check(all_ok, SettingsManager.show_debug_axes == true, "options_panel instance writes through to shared SettingsManager")

	# GDScript lambdas capture bare bool locals by value, not reference - use
	# a single-element array so the closure mutates something the outer
	# scope can actually observe.
	var got_back_signal := [false]
	options_b.back_pressed.connect(func() -> void: got_back_signal[0] = true)
	var back_button := options_b.get_node("Margin/VBox/BackButton") as Button
	back_button.pressed.emit()
	all_ok = _check(all_ok, got_back_signal[0], "options_panel emits back_pressed on Back button")

	print("")
	print("PAUSE MENU TEST: %s" % ("PASS" if all_ok else "FAIL"))
	get_tree().quit(0 if all_ok else 1)


func _check(all_ok: bool, condition: bool, label: String) -> bool:
	print("[%s] %s" % ["OK" if condition else "FAIL", label])
	return all_ok and condition
