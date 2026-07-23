extends Node
## Determines whether Malik's glTF model actually faces Godot's forward
## convention (-Z) or the glTF spec default (+Z, which Godot does NOT
## auto-correct on import - confirmed via web research, godotengine/godot
## issue #45578 and godot-proposals #6198).
##
## Method: read the skeleton's actual bone rest-pose positions. Godot's
## unambiguous, independently-verified convention (Camera3D at identity
## looks down -Z with +X to the right of the view) means a character
## authored to face -Z has their own anatomical RIGHT side toward world +X.
## So: if a "right"-named bone sits at local +X, the model faces -Z
## (correct, matches engine forward). If it sits at -X, the model faces
## +Z (backwards - needs a 180 deg fix).
##
## Run: godot --headless --path . res://test/facing_diagnostic.tscn

const MALIK_SCENE := "res://scenes/characters/malik.tscn"


func _ready() -> void:
	var malik: Node = (load(MALIK_SCENE) as PackedScene).instantiate()
	add_child(malik)

	var skeleton := _find_skeleton(malik)
	if skeleton == null:
		print("No Skeleton3D found under malik.tscn")
		get_tree().quit(1)
		return

	print("== FACING DIAGNOSTIC ==")
	print("Skeleton3D found: %s" % skeleton.get_path())
	print("Skeleton3D.global_transform = %s" % skeleton.global_transform)
	print("Bone count: %d" % skeleton.get_bone_count())
	print("")
	print("Bone names + WORLD-space position (skeleton.global_transform * bone_global_rest.origin):")
	var left_x := []
	var right_x := []
	for i in skeleton.get_bone_count():
		var bname := skeleton.get_bone_name(i)
		var global_rest := skeleton.get_bone_global_rest(i)
		var world_pos: Vector3 = skeleton.global_transform * global_rest.origin
		print("  [%d] %-30s world_pos=%s" % [i, bname, world_pos])
		var lname := bname.to_lower()
		if "left" in lname or lname.ends_with("_l") or lname.ends_with(".l"):
			left_x.append(world_pos.x)
		elif "right" in lname or lname.ends_with("_r") or lname.ends_with(".r"):
			right_x.append(world_pos.x)

	print("")
	if left_x.is_empty() and right_x.is_empty():
		print("No left/right-named bones found - cannot determine facing this way.")
	else:
		var avg_left: float = 0.0
		for v in left_x:
			avg_left += v
		if left_x.size() > 0:
			avg_left /= left_x.size()
		var avg_right: float = 0.0
		for v in right_x:
			avg_right += v
		if right_x.size() > 0:
			avg_right /= right_x.size()
		print("avg 'left'-named bone global X:  %f  (n=%d)" % [avg_left, left_x.size()])
		print("avg 'right'-named bone global X: %f  (n=%d)" % [avg_right, right_x.size()])
		print("")
		if right_x.size() > 0 and avg_right > avg_left:
			print("CONCLUSION: right-side bones at +X => model faces -Z (Godot's forward). Model orientation is CORRECT.")
		elif right_x.size() > 0 and avg_right < avg_left:
			print("CONCLUSION: right-side bones at -X => model faces +Z (glTF default, backwards vs Godot forward). Model needs a 180deg Y fix.")
		else:
			print("CONCLUSION: inconclusive from bone names alone.")

	get_tree().quit(0)


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null
