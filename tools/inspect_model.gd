extends SceneTree
## Read-only diagnostic - prints the full node tree of a model with each
## node's local position, so front/back/left/right can be identified from
## actual named parts (e.g. wheel_front/wheel_back) instead of guessed.
## Usage: godot --headless --path . --script tools/inspect_model.gd -- <res://path.glb>

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1:
		printerr("Usage: godot --headless --path . --script tools/inspect_model.gd -- <res://path.glb>")
		quit(1)
		return
	var path := args[0]
	if not ResourceLoader.exists(path):
		printerr("Not found: %s" % path)
		quit(1)
		return
	var scene: PackedScene = load(path)
	var inst: Node = scene.instantiate()
	root.add_child(inst)
	_print_tree(inst, 0)
	inst.queue_free()
	quit(0)


func _print_tree(node: Node, depth: int) -> void:
	var indent := "  ".repeat(depth)
	var pos_str := ""
	if node is Node3D:
		pos_str = " pos=%s" % (node as Node3D).position
	print("%s%s (%s)%s" % [indent, node.name, node.get_class(), pos_str])
	for child in node.get_children():
		_print_tree(child, depth + 1)
