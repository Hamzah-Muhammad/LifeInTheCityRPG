class_name Interactable
extends Area3D
## Anything Malik can walk up to and press E on.
## Put the Area3D on collision layer 2 (the player's InteractionSensor scans
## layer 2 only). Set a prompt and point it at a dialogue file + entry node.

@export var prompt: String = "E — Interact"
@export_file("*.json") var dialogue_file: String = ""
@export var dialogue_entry: String = "start"


func interact() -> void:
	if dialogue_file != "":
		DialogueManager.start(dialogue_file, dialogue_entry)
