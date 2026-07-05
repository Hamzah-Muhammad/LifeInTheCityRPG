extends Node
## Autoload "DialogueManager" — loads a dialogue JSON file and walks its nodes.
##
## Dialogue files live in res://data/dialogue/*.json. Each file is a dictionary
## of nodes keyed by id:
##   {
##     "start": {
##       "speaker": "Malik",
##       "text": "...",
##       "choices": [
##         {"text": "...", "next": "other_id", "effects": {"rep": 1, "flags": ["did_thing"]}}
##       ]
##     },
##     "other_id": {"speaker": "...", "text": "...", "next": "end"}
##   }
## Nodes without "choices" use "next" (default "end"). "effects" on a node or a
## choice apply stat deltas / story flags via GameState.
##
## UI (DialogueUI) listens to the signals; gameplay checks `active` to freeze.

signal dialogue_started
signal node_entered(node: Dictionary)
signal dialogue_ended

var active: bool = false

var _nodes: Dictionary = {}
var _current_id: String = ""


func start(json_path: String, entry: String = "start") -> void:
	if active:
		return
	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("DialogueManager: cannot open '%s'" % json_path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("DialogueManager: '%s' is not valid dialogue JSON" % json_path)
		return
	_nodes = parsed
	active = true
	dialogue_started.emit()
	_enter(entry)


## Advance a choice-less node to its "next".
func advance() -> void:
	var node: Dictionary = _nodes.get(_current_id, {})
	_enter(str(node.get("next", "end")))


## Pick choice `index` on the current node.
func choose(index: int) -> void:
	var node: Dictionary = _nodes.get(_current_id, {})
	var choices: Array = node.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	_apply_effects(choice.get("effects", {}))
	_enter(str(choice.get("next", "end")))


func _enter(id: String) -> void:
	if id == "end" or not _nodes.has(id):
		_finish()
		return
	_current_id = id
	var node: Dictionary = _nodes[id]
	_apply_effects(node.get("effects", {}))
	node_entered.emit(node)


func _apply_effects(effects: Dictionary) -> void:
	for key: String in effects:
		if key == "flags":
			for flag in effects[key]:
				GameState.set_flag(str(flag))
		else:
			GameState.adjust(key, int(effects[key]))


func _finish() -> void:
	active = false
	_nodes = {}
	_current_id = ""
	dialogue_ended.emit()
