extends CanvasLayer
## Renders whatever DialogueManager is doing: speaker, line, choice buttons.
## Choice-less nodes get a single "Continue" button. Buttons are keyboard
## focusable, so Enter/Space also advances.

@onready var _panel: PanelContainer = $Panel
@onready var _speaker: Label = $Panel/Margin/VBox/Speaker
@onready var _text: Label = $Panel/Margin/VBox/Text
@onready var _choices: VBoxContainer = $Panel/Margin/VBox/Choices


func _ready() -> void:
	_panel.visible = false
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.node_entered.connect(_on_node_entered)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_dialogue_started() -> void:
	_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_dialogue_ended() -> void:
	_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_node_entered(node: Dictionary) -> void:
	_speaker.text = str(node.get("speaker", ""))
	_text.text = str(node.get("text", ""))

	for child in _choices.get_children():
		child.queue_free()

	var first_button: Button = null
	var choices: Array = node.get("choices", [])
	if choices.is_empty():
		first_button = _add_button("Continue", DialogueManager.advance)
	else:
		for i in choices.size():
			var button := _add_button(str(choices[i].get("text", "...")), DialogueManager.choose.bind(i))
			if first_button == null:
				first_button = button
	first_button.grab_focus()


func _add_button(label: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(on_pressed)
	_choices.add_child(button)
	return button
