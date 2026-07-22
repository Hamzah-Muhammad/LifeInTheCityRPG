class_name ApartmentFrontDoor
extends Interactable
## The apartment's front door. Same narrative gate as before (dialogue asks
## "head out" vs "stay in") — but choosing to leave now actually walks Malik
## out into the open world once the dialogue finishes, instead of ending on
## placeholder text.
##
## The dialogue's exit node sets the LEFT_FLAG story flag as its effect; we
## clear it before every attempt so a stale flag from a previous visit can
## never cause a wrong-branch (e.g. "stay in tonight") to travel by mistake.

const LEFT_FLAG := "left_apartment_tonight"

@export_file("*.tscn") var exit_scene: String = ""
@export var exit_marker: String = ""


func interact() -> void:
	GameState.flags.erase(LEFT_FLAG)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)
	super.interact()


func _on_dialogue_ended() -> void:
	if GameState.has_flag(LEFT_FLAG):
		SceneTransition.go(exit_scene, exit_marker)
