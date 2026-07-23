extends SceneTree
## Read-only diagnostic - creates a Label3D and prints its relevant property
## values/defaults, so sign-facing behavior is verified instead of guessed.
## Usage: godot --headless --path . --script tools/inspect_label3d.gd

func _initialize() -> void:
	var label := Label3D.new()
	root.add_child(label)
	print("billboard (default) = %s" % label.billboard)
	print("billboard enum values: DISABLED=%s ENABLED=%s FIXED_Y=%s" % [
		BaseMaterial3D.BILLBOARD_DISABLED, BaseMaterial3D.BILLBOARD_ENABLED, BaseMaterial3D.BILLBOARD_FIXED_Y
	])
	print("double_sided (default) = %s" % label.double_sided)
	print("no_depth_test (default) = %s" % label.no_depth_test)
	print("fixed_size (default) = %s" % label.fixed_size)
	print("alpha_cut (default) = %s" % label.alpha_cut)
	print("render_priority (default) = %s" % label.render_priority)
	label.queue_free()
	quit(0)
