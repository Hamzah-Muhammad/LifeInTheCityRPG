extends Node
## Headless smoke test for the dialogue engine + game state.
## Run: godot --headless --path . res://test/smoke_test.tscn
## Walks the phone conversation, picks the "omw" choice, and asserts the
## stat/flag effects landed. Exits 0 on pass, 1 on fail.


func _ready() -> void:
	var log_lines: Array[String] = []
	DialogueManager.node_entered.connect(
		func(node: Dictionary) -> void:
			log_lines.append("NODE  %s: %s" % [node.get("speaker", "(narrator)"), str(node.get("text", "")).left(50)])
	)
	DialogueManager.dialogue_ended.connect(func() -> void: log_lines.append("ENDED"))

	DialogueManager.start("res://data/dialogue/act0_bedroom.json", "phone_1")
	DialogueManager.advance()  # phone_1 -> phone_2
	DialogueManager.choose(0)  # phone_2 -> phone_yes (+1 rep, flags)
	DialogueManager.advance()  # phone_yes -> end

	print("== SMOKE TEST ==")
	for line in log_lines:
		print(line)
	print("rep=%d loyalty=%d cash=%d flags=%s" % [
		GameState.rep, GameState.loyalty, GameState.cash, str(GameState.flags),
	])

	var passed := (
		GameState.rep == 1
		and GameState.has_flag("texted_ty")
		and GameState.has_flag("checked_phone")
		and not DialogueManager.active
	)
	print("SMOKE RESULT: %s" % ("PASS" if passed else "FAIL"))
	get_tree().quit(0 if passed else 1)
