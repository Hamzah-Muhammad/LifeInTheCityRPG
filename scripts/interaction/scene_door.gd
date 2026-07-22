class_name SceneDoor
extends Interactable
## A physical door: interacting moves Malik to another scene via
## SceneTransition instead of starting dialogue. Same Area3D/layer-2/E-prompt
## convention as Interactable — just a different action on interact().

@export_file("*.tscn") var target_scene: String = ""
@export var target_marker: String = ""


func interact() -> void:
	SceneTransition.go(target_scene, target_marker)
