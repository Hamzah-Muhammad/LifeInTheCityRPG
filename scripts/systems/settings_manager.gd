extends Node
## Autoload "SettingsManager" — Display/Graphics/Audio/Controls options.
## Persists to user://settings.cfg and applies them to the engine on load
## and whenever a setter is called from the Options menu.

const SAVE_PATH := "user://settings.cfg"
const BASE_MOUSE_SENSITIVITY := 0.0025

enum WindowMode { WINDOWED, FULLSCREEN, BORDERLESS }

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

var window_mode: int = WindowMode.WINDOWED
var resolution: Vector2i = Vector2i(1600, 900)
var vsync: bool = true
var antialiasing: bool = true
var master_volume: float = 1.0
var mouse_sensitivity_multiplier: float = 1.0
var show_debug_axes: bool = false


func _ready() -> void:
	_load()
	apply_all()


func apply_all() -> void:
	_apply_window_mode()
	_apply_vsync()
	_apply_antialiasing()
	_apply_master_volume()


func set_window_mode(mode: int) -> void:
	window_mode = mode
	_apply_window_mode()
	_save()


func set_resolution(res: Vector2i) -> void:
	resolution = res
	if window_mode != WindowMode.FULLSCREEN:
		DisplayServer.window_set_size(resolution)
	_save()


func set_vsync(enabled: bool) -> void:
	vsync = enabled
	_apply_vsync()
	_save()


func set_antialiasing(enabled: bool) -> void:
	antialiasing = enabled
	_apply_antialiasing()
	_save()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_master_volume()
	_save()


func set_mouse_sensitivity(multiplier: float) -> void:
	mouse_sensitivity_multiplier = multiplier
	_save()


func set_show_debug_axes(enabled: bool) -> void:
	show_debug_axes = enabled
	_save()


func _apply_window_mode() -> void:
	match window_mode:
		WindowMode.FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		WindowMode.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(resolution)
		_:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(resolution)


func _apply_vsync() -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)


func _apply_antialiasing() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_2X if antialiasing else Viewport.MSAA_DISABLED


func _apply_master_volume() -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(maxf(master_volume, 0.0001)))


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	window_mode = cfg.get_value("display", "window_mode", window_mode)
	resolution = cfg.get_value("display", "resolution", resolution)
	vsync = cfg.get_value("display", "vsync", vsync)
	antialiasing = cfg.get_value("graphics", "antialiasing", antialiasing)
	master_volume = cfg.get_value("audio", "master_volume", master_volume)
	mouse_sensitivity_multiplier = cfg.get_value(
		"controls", "mouse_sensitivity", mouse_sensitivity_multiplier
	)
	show_debug_axes = cfg.get_value("debug", "show_debug_axes", show_debug_axes)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "window_mode", window_mode)
	cfg.set_value("display", "resolution", resolution)
	cfg.set_value("display", "vsync", vsync)
	cfg.set_value("graphics", "antialiasing", antialiasing)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity_multiplier)
	cfg.set_value("debug", "show_debug_axes", show_debug_axes)
	cfg.save(SAVE_PATH)
