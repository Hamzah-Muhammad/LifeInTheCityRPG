extends CanvasLayer
## Renders StationManager's area list. Unlocked entries are clickable and
## travel there; locked ones show as disabled "Coming Soon" buttons.

@onready var _panel: PanelContainer = $Panel
@onready var _list: VBoxContainer = $Panel/Margin/VBox/List


func _ready() -> void:
	_panel.visible = false
	StationManager.opened.connect(_on_opened)
	StationManager.closed.connect(_on_closed)


func _on_opened() -> void:
	_rebuild_list()
	_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_closed() -> void:
	_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _rebuild_list() -> void:
	for child in _list.get_children():
		child.queue_free()

	var first_button: Button = null
	for area: Dictionary in StationManager.AREAS:
		var unlocked: bool = area.get("unlocked", false)
		var button := Button.new()
		button.text = str(area.get("label", "")) + ("" if unlocked else " (Coming Soon)")
		button.disabled = not unlocked
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if unlocked:
			button.pressed.connect(StationManager.travel.bind(str(area.get("id", ""))))
			if first_button == null:
				first_button = button
		_list.add_child(button)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	close_button.pressed.connect(StationManager.close)
	_list.add_child(close_button)
	if first_button == null:
		first_button = close_button
	first_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _panel.visible and event.is_action_pressed("ui_cancel"):
		StationManager.close()
