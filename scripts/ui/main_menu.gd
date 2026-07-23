extends CanvasLayer
## Startup menu: New Game / Load Game / Options / Quit.
## Options is the shared options_panel.tscn component (also used by
## pause_menu.gd in-game) - this script just shows/hides it and reacts to
## its back_pressed signal.
## New Game routes through a character-creation screen (name + gender) before
## GameState.reset() and the scene change; Load Game hands off to SaveManager.

const NEW_GAME_SCENE := "res://scenes/apartment/malik_bedroom.tscn"

@onready var _menu_panel: PanelContainer = $MenuPanel
@onready var _options_panel: PanelContainer = $OptionsPanel
@onready var _creation_panel: PanelContainer = $CharacterCreationPanel

@onready var _new_game_button: Button = $MenuPanel/Margin/VBox/NewGameButton
@onready var _load_game_button: Button = $MenuPanel/Margin/VBox/LoadGameButton
@onready var _options_button: Button = $MenuPanel/Margin/VBox/OptionsButton
@onready var _quit_button: Button = $MenuPanel/Margin/VBox/QuitButton

@onready var _name_edit: LineEdit = $CharacterCreationPanel/Margin/VBox/NameEdit
@onready var _male_button: Button = $CharacterCreationPanel/Margin/VBox/GenderRow/MaleButton
@onready var _female_button: Button = $CharacterCreationPanel/Margin/VBox/GenderRow/FemaleButton
@onready var _creation_back_button: Button = $CharacterCreationPanel/Margin/VBox/ButtonRow/BackButton
@onready var _begin_button: Button = $CharacterCreationPanel/Margin/VBox/ButtonRow/BeginButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_new_game_button.pressed.connect(_on_new_game_pressed)
	_load_game_button.pressed.connect(_on_load_game_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	_options_panel.back_pressed.connect(_on_options_back_pressed)
	_creation_back_button.pressed.connect(_on_creation_back_pressed)
	_begin_button.pressed.connect(_on_begin_pressed)

	_load_game_button.disabled = not SaveManager.has_save()
	_load_game_button.tooltip_text = "" if SaveManager.has_save() else "No save file yet."

	_new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	_menu_panel.visible = false
	_creation_panel.visible = true
	_name_edit.text = ""
	_male_button.button_pressed = true
	_name_edit.grab_focus()


func _on_load_game_pressed() -> void:
	SaveManager.load_game()


func _on_begin_pressed() -> void:
	GameState.reset()
	var chosen_name := _name_edit.text.strip_edges()
	if chosen_name != "":
		GameState.player_name = chosen_name
	GameState.player_gender = "male" if _male_button.button_pressed else "female"
	get_tree().change_scene_to_file(NEW_GAME_SCENE)


func _on_creation_back_pressed() -> void:
	_creation_panel.visible = false
	_menu_panel.visible = true


func _on_options_pressed() -> void:
	_menu_panel.visible = false
	_options_panel.visible = true


func _on_options_back_pressed() -> void:
	_options_panel.visible = false
	_menu_panel.visible = true
