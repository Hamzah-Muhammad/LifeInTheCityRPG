extends PanelContainer
## Options UI: Display/Graphics/Audio/Controls/Debug, writing straight
## through to SettingsManager. Self-contained and reusable - instanced by
## both main_menu.tscn (pre-game) and pause_menu.tscn (in-game), so there is
## one settings implementation, not two that could drift out of sync.
## Parent decides what "Back" means by listening for back_pressed.

signal back_pressed

@onready var _window_mode_option: OptionButton = $Margin/VBox/DisplayGrid/WindowModeOption
@onready var _resolution_option: OptionButton = $Margin/VBox/DisplayGrid/ResolutionOption
@onready var _vsync_check: CheckBox = $Margin/VBox/DisplayGrid/VSyncCheck
@onready var _antialiasing_check: CheckBox = $Margin/VBox/GraphicsGrid/AntiAliasingCheck
@onready var _master_volume_slider: HSlider = $Margin/VBox/AudioGrid/MasterVolumeSlider
@onready var _mouse_sensitivity_slider: HSlider = $Margin/VBox/ControlsGrid/MouseSensitivitySlider
@onready var _show_debug_axes_check: CheckBox = $Margin/VBox/DebugGrid/ShowDebugAxesCheck
@onready var _back_button: Button = $Margin/VBox/BackButton


func _ready() -> void:
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

	_show_debug_axes_check.button_pressed = SettingsManager.show_debug_axes
	_show_debug_axes_check.toggled.connect(SettingsManager.set_show_debug_axes)

	_back_button.pressed.connect(func() -> void: back_pressed.emit())


func _on_window_mode_selected(index: int) -> void:
	SettingsManager.set_window_mode(_window_mode_option.get_item_id(index))


func _on_resolution_selected(index: int) -> void:
	SettingsManager.set_resolution(SettingsManager.RESOLUTIONS[index])
