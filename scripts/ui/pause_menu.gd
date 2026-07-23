extends CanvasLayer
## Renders PauseManager's open/closed state: Resume / Options / Quit to Main
## Menu. Options is the same shared options_panel.tscn component the main
## menu uses - one settings implementation, not two.

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var _background: ColorRect = $Background
@onready var _panel: PanelContainer = $Panel
@onready var _options_panel: PanelContainer = $OptionsPanel
@onready var _resume_button: Button = $Panel/Margin/VBox/ResumeButton
@onready var _options_button: Button = $Panel/Margin/VBox/OptionsButton
@onready var _quit_button: Button = $Panel/Margin/VBox/QuitToMenuButton


func _ready() -> void:
	PauseManager.opened.connect(_on_opened)
	PauseManager.closed.connect(_on_closed)
	_resume_button.pressed.connect(func() -> void: PauseManager.close())
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_options_panel.back_pressed.connect(_on_options_back_pressed)


func _on_opened() -> void:
	_background.visible = true
	_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_closed() -> void:
	_background.visible = false
	_panel.visible = false
	_options_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_options_pressed() -> void:
	_panel.visible = false
	_options_panel.visible = true


func _on_options_back_pressed() -> void:
	_options_panel.visible = false
	_panel.visible = true


func _on_quit_pressed() -> void:
	PauseManager.close()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
