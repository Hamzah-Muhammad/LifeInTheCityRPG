extends SceneTree
## Generic version of test/facing_diagnostic.gd (which is hardcoded to
## Malik) - checks any rigged glTF character's actual facing direction via
## its skeleton's bone rest-pose world positions, per the project's
## established rule: verify every new Quaternius/glTF character before
## placing it, don't assume orientation. See test/facing_diagnostic.gd for
## the full method writeup.
##
## Usage: godot --headless --path . --script tools/facing_diagnostic_generic.gd -- <res://path.gltf>

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1:
		printerr("Usage: godot --headless --path . --script tools/facing_diagnostic_generic.gd -- <res://path.gltf>")
		quit(1)
		return
	var path := args[0]
	if not ResourceLoader.exists(path):
		printerr("Not found: %s" % path)
		quit(1)
		return

	var inst: Node = (load(path) as PackedScene).instantiate()
	root.add_child(inst)

	var skeleton := _find_skeleton(inst)
	if skeleton == null:
		print("%s: No Skeleton3D found" % path)
		inst.queue_free()
		quit(1)
		return

	var left_x := []
	var right_x := []
	for i in skeleton.get_bone_count():
		var bname := skeleton.get_bone_name(i)
		var global_rest := skeleton.get_bone_global_rest(i)
		var world_pos: Vector3 = skeleton.global_transform * global_rest.origin
		var lname := bname.to_lower()
		if "left" in lname or lname.ends_with("_l") or lname.ends_with(".l"):
			left_x.append(world_pos.x)
		elif "right" in lname or lname.ends_with("_r") or lname.ends_with(".r"):
			right_x.append(world_pos.x)

	if left_x.is_empty() and right_x.is_empty():
		print("%s: No left/right-named bones found - inconclusive" % path)
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
		if right_x.size() > 0 and avg_right > avg_left:
			print("%s: right-bones at +X => faces -Z (CORRECT, no fix needed)" % path)
		elif right_x.size() > 0 and avg_right < avg_left:
			print("%s: right-bones at -X => faces +Z (BACKWARDS, needs 180deg Y fix)" % path)
		else:
			print("%s: inconclusive (avg_left=%f avg_right=%f)" % [path, avg_left, avg_right])

	inst.queue_free()
	quit(0)


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null
