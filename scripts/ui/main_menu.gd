extends CanvasLayer
## Startup menu: New Game / Load Game / Options / Quit.
## Options writes straight through to SettingsManager, which persists to
## user://settings.cfg and applies each change to the engine immediately.
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

@onready var _window_mode_option: OptionButton = $OptionsPanel/Margin/VBox/DisplayGrid/WindowModeOption
@onready var _resolution_option: OptionButton = $OptionsPanel/Margin/VBox/DisplayGrid/ResolutionOption
@onready var _vsync_check: CheckBox = $OptionsPanel/Margin/VBox/DisplayGrid/VSyncCheck
@onready var _antialiasing_check: CheckBox = $OptionsPanel/Margin/VBox/GraphicsGrid/AntiAliasingCheck
@onready var _master_volume_slider: HSlider = $OptionsPanel/Margin/VBox/AudioGrid/MasterVolumeSlider
@onready var _mouse_sensitivity_slider: HSlider = $OptionsPanel/Margin/VBox/ControlsGrid/MouseSensitivitySlider
@onready var _options_back_button: Button = $OptionsPanel/Margin/VBox/BackButton

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
	_options_back_button.pressed.connect(_on_options_back_pressed)
	_creation_back_button.pressed.connect(_on_creation_back_pressed)
	_begin_button.pressed.connect(_on_begin_pressed)

	_load_game_button.disabled = not SaveManager.has_save()
	_load_game_button.tooltip_text = "" if SaveManager.has_save() else "No save file yet."

	_populate_options()
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


func _populate_options() -> void:
	_window_mode_option.add_item("Windowed", SettingsManager.WindowMode.WINDOWED)
	_window_mode_option.add_item("Fullscreen", SettingsManager.WindowMode.FULLSCREEN)
	_window_mode_option.add_item("Borderless", SettingsManager.WindowMode.BORDERLESS)
	_window_mode_option.select(_window_mode_option.get_item_index(SettingsManager.window_mode))
	_window_mode_option.item_selected.connect(_on_window_mode_selected)

	for res: Vector2i in SettingsManager.RESOLUTIONS:
		_resolution_option.add_item("%d x %d" % [res.x, res.y])
	var res_index := SettingsManager.RESOLUTIONS.find(SettingsManager.resolution)
	_resolution_option.select(maxi(res_index, 0))
	_resolution_option.item_selected.connect(_on_resolution_selected)

	_vsync_check.button_pressed = SettingsManager.vsync
	_vsync_check.toggled.connect(SettingsManager.set_vsync)

	_antialiasing_check.button_pressed = SettingsManager.antialiasing
	_antialiasing_check.toggled.connect(SettingsManager.set_antialiasing)

	_master_volume_slider.value = SettingsManager.master_volume
	_master_volume_slider.value_changed.connect(SettingsManager.set_master_volume)

	_mouse_sensitivity_slider.value = SettingsManager.mouse_sensitivity_multiplier
	_mouse_sensitivity_slider.value_changed.connect(SettingsManager.set_mouse_sensitivity)


func _on_window_mode_selected(index: int) -> void:
	SettingsManager.set_window_mode(_window_mode_option.get_item_id(index))


func _on_resolution_selected(index: int) -> void:
	SettingsManager.set_resolution(SettingsManager.RESOLUTIONS[index])
