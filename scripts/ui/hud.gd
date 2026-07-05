extends CanvasLayer
## Debug/dev HUD: live stat readout (top-left) and the interact prompt
## (bottom-center). The stat bar makes choice effects visible while we build;
## it gets a proper diegetic treatment later.

@onready var _stats: Label = $StatsLabel
@onready var _prompt: Label = $PromptLabel

var _last_prompt: String = ""


func _ready() -> void:
	GameState.stat_changed.connect(_on_stat_changed)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	_refresh_stats()

	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.interact_target_changed.connect(_on_interact_target_changed)


func _on_stat_changed(_stat: String, _value: int) -> void:
	_refresh_stats()


func _refresh_stats() -> void:
	_stats.text = "REP %d    HEAT %d    LOYALTY %d    CASH $%d" % [
		GameState.rep, GameState.heat, GameState.loyalty, GameState.cash,
	]


func _on_interact_target_changed(prompt: String) -> void:
	_last_prompt = prompt
	_prompt.text = prompt
	_prompt.visible = prompt != "" and not DialogueManager.active


func _on_dialogue_started() -> void:
	_prompt.visible = false


func _on_dialogue_ended() -> void:
	_prompt.text = _last_prompt
	_prompt.visible = _last_prompt != ""
