extends SceneTree
## Compiles a 2D floor-plan JSON (leveldesign/floorplans/*.json) into a real
## Godot .tscn, using leveldesign/furniture_catalog.json for per-model
## recentering offsets and collision sizes.
##
## Usage: godot --headless --path . --script tools/generate_scene.gd -- <floorplan.json>
##
## Deliberately does NOT load/instantiate the target scene or any node
## scripts - it only computes Basis/Vector3 math and writes plain .tscn text
## via FileAccess. This sidesteps the documented gotcha where resaving a
## scene via PackedScene.pack()/ResourceSaver.save() from bare --script mode
## silently drops @export data on scripted nodes (autoloads don't resolve
## there). Every node type this script emits (StaticBody3D, MeshInstance3D,
## CollisionShape3D, Marker3D, Area3D+script) is just text - never loaded.

const CATALOG_PATH := "res://leveldesign/furniture_catalog.json"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1:
		printerr("Usage: godot --headless --path . --script tools/generate_scene.gd -- <floorplan.json>")
		quit(1)
		return

	var floorplan: Dictionary = _load_json(args[0])
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	if floorplan.is_empty() or catalog.is_empty():
		quit(1)
		return

	var errors := _check_overlaps(floorplan, catalog)
	if not errors.is_empty():
		printerr("GENERATION ABORTED - overlapping geometry found:")
		for e in errors:
			printerr("  - " + e)
		quit(1)
		return

	var tscn_text := _build_tscn(floorplan, catalog)
	var out_path: String = floorplan.get("output_path", "")
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		printerr("Could not open '%s' for writing (error %s)" % [out_path, FileAccess.get_open_error()])
		quit(1)
		return
	file.store_string(tscn_text)
	file.close()

	print("OK: wrote %s" % out_path)
	quit(0)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("Could not open '%s'" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		printerr("'%s' is not a valid JSON object" % path)
		return {}
	return parsed


## Rotates the X/Z components of a 3-element array [x,y,z] by angle_deg around
## Y, matching Basis().rotated(Vector3.UP, deg_to_rad(90)) == x_axis=(0,0,-1),
## z_axis=(1,0,0) (verified against the live engine this project already
## depends on - see project memory Gotchas).
func _rotate_xz(v: Array, angle_deg: float) -> Vector3:
	var rad := deg_to_rad(angle_deg)
	var c := cos(rad)
	var s := sin(rad)
	var x: float = v[0]
	var z: float = v[2]
	return Vector3(x * c + z * s, v[1], -x * s + z * c)


func _obb_corners(center: Vector2, half_extents: Vector2, angle_deg: float) -> PackedVector2Array:
	var rad := deg_to_rad(angle_deg)
	var c := cos(rad)
	var s := sin(rad)
	var corners := PackedVector2Array()
	var signs_list: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	for signs: Vector2 in signs_list:
		var lx: float = half_extents.x * signs.x
		var lz: float = half_extents.y * signs.y
		# Same Ry(angle) convention as _rotate_xz, applied in the XZ plane (y -> "z" here).
		var wx: float = lx * c + lz * s
		var wz: float = -lx * s + lz * c
		corners.append(center + Vector2(wx, wz))
	return corners


## Separating Axis Theorem for two convex quads - correct for arbitrary
## rotations (an axis-aligned approximation would miss/false-flag rotated
## furniture, which is exactly the kind of bug this pipeline exists to catch).
func _obb_overlap(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	var polys: Array[PackedVector2Array] = [a, b]
	for poly: PackedVector2Array in polys:
		for i in poly.size():
			var p1: Vector2 = poly[i]
			var p2: Vector2 = poly[(i + 1) % poly.size()]
			var axis := Vector2(-(p2.y - p1.y), p2.x - p1.x).normalized()
			var min_a := INF
			var max_a := -INF
			for pt in a:
				var proj := pt.dot(axis)
				min_a = minf(min_a, proj)
				max_a = maxf(max_a, proj)
			var min_b := INF
			var max_b := -INF
			for pt in b:
				var proj := pt.dot(axis)
				min_b = minf(min_b, proj)
				max_b = maxf(max_b, proj)
			if max_a < min_b or max_b < min_a:
				return false
	return true


func _footprint_for_furniture(item: Dictionary, catalog: Dictionary) -> Dictionary:
	var entry: Dictionary = catalog.get(item.get("catalog_id", ""), {})
	if not entry.get("has_collision", false):
		return {}
	var size: Array = entry["collision_size"]
	var offset: Array = entry.get("collision_offset", [0, 0, 0])
	var rot: float = item.get("rot_y", 0.0)
	var rotated_offset := _rotate_xz(offset, rot)
	var pos: Array = item["pos"]
	var center := Vector2(pos[0] + rotated_offset.x, pos[1] + rotated_offset.z)
	return {
		"corners": _obb_corners(center, Vector2(size[0], size[2]) * 0.5, rot),
		"label": item.get("catalog_id", "?"),
	}


func _footprint_for_wall(wall: Dictionary) -> Dictionary:
	var from: Array = wall["from"]
	var to: Array = wall["to"]
	var thickness: float = wall.get("thickness", 0.2)
	var dx: float = to[0] - from[0]
	var dz: float = to[1] - from[1]
	var length := Vector2(dx, dz).length()
	var angle_deg := rad_to_deg(atan2(-dz, dx))
	var center := Vector2((from[0] + to[0]) * 0.5, (from[1] + to[1]) * 0.5)
	return {
		"corners": _obb_corners(center, Vector2(length, thickness) * 0.5, angle_deg),
		"label": "wall",
	}


## Walls are checked against furniture, but NOT against each other - adjacent
## walls sharing a corner always overlap slightly by construction (every
## rectangular room does this at every corner), so that pairing would be a
## constant false positive, not a real bug. Only furniture-vs-furniture and
## furniture-vs-wall pairs represent an actual "something is blocking a path
## or clipping through something else" problem.
func _check_overlaps(floorplan: Dictionary, catalog: Dictionary) -> Array:
	var wall_footprints: Array[Dictionary] = []
	for wall: Dictionary in floorplan.get("walls", []):
		wall_footprints.append(_footprint_for_wall(wall))

	var furniture_footprints: Array[Dictionary] = []
	for item: Dictionary in floorplan.get("furniture", []):
		var fp := _footprint_for_furniture(item, catalog)
		if not fp.is_empty():
			furniture_footprints.append(fp)

	var errors: Array[String] = []
	for i in furniture_footprints.size():
		for j in range(i + 1, furniture_footprints.size()):
			if _obb_overlap(furniture_footprints[i]["corners"], furniture_footprints[j]["corners"]):
				errors.append(
					"%s (#%d) overlaps %s (#%d)"
					% [furniture_footprints[i]["label"], i, furniture_footprints[j]["label"], j]
				)
		for w in wall_footprints.size():
			if _obb_overlap(furniture_footprints[i]["corners"], wall_footprints[w]["corners"]):
				errors.append("%s (#%d) overlaps wall (#%d)" % [furniture_footprints[i]["label"], i, w])
	return errors


func _basis_lines(rot_deg: float, scale: float) -> String:
	var rad := deg_to_rad(rot_deg)
	var c := cos(rad) * scale
	var s := sin(rad) * scale
	# x_axis=(c,0,-s), y_axis=(0,scale,0), z_axis=(s,0,c) - matches the
	# verified Basis().rotated(Vector3.UP, angle) convention.
	return "%s, 0, %s, 0, %s, 0, %s, 0, %s" % [c, -s, scale, s, c]


func _build_tscn(floorplan: Dictionary, catalog: Dictionary) -> String:
	var ext_resources: Array[String] = []
	var sub_resources: Array[String] = []
	var nodes: Array[String] = []
	var model_res_ids: Dictionary = {}  # catalog_id -> "N_id"
	var res_counter := 1

	for item: Dictionary in floorplan.get("furniture", []):
		var cid: String = item["catalog_id"]
		if not model_res_ids.has(cid):
			var entry: Dictionary = catalog[cid]
			var res_id := "%d_%s" % [res_counter, cid]
			res_counter += 1
			ext_resources.append(
				'[ext_resource type="PackedScene" path="%s" id="%s"]' % [entry["model"], res_id]
			)
			model_res_ids[cid] = res_id

	sub_resources.append('[sub_resource type="StandardMaterial3D" id="mat_wall"]')
	sub_resources.append("albedo_color = Color(0.78, 0.75, 0.7, 1)")
	sub_resources.append("")
	sub_resources.append('[sub_resource type="StandardMaterial3D" id="mat_floor"]')
	sub_resources.append("albedo_color = Color(0.42, 0.34, 0.26, 1)")
	sub_resources.append("")

	nodes.append('[node name="%s" type="Node3D"]' % floorplan.get("scene_name", "GeneratedScene"))
	nodes.append("")
	nodes.append('[node name="Geometry" type="Node3D" parent="."]')
	nodes.append("")

	var wall_i := 0
	for wall: Dictionary in floorplan.get("walls", []):
		wall_i += 1
		var from: Array = wall["from"]
		var to: Array = wall["to"]
		var height: float = wall.get("height", 2.6)
		var thickness: float = wall.get("thickness", 0.2)
		var dx: float = to[0] - from[0]
		var dz: float = to[1] - from[1]
		var length := Vector2(dx, dz).length()
		var angle_deg := rad_to_deg(atan2(-dz, dx))
		var cx: float = (from[0] + to[0]) * 0.5
		var cz: float = (from[1] + to[1]) * 0.5
		var mesh_id := "m_wall_%d" % wall_i
		var shape_id := "s_wall_%d" % wall_i
		sub_resources.append('[sub_resource type="BoxMesh" id="%s"]' % mesh_id)
		sub_resources.append("size = Vector3(%s, %s, %s)" % [length, height, thickness])
		sub_resources.append("")
		sub_resources.append('[sub_resource type="BoxShape3D" id="%s"]' % shape_id)
		sub_resources.append("size = Vector3(%s, %s, %s)" % [length, height, thickness])
		sub_resources.append("")

		var basis := _basis_lines(angle_deg, 1.0)
		var node_name := "Wall%d" % wall_i
		nodes.append('[node name="%s" type="StaticBody3D" parent="Geometry"]' % node_name)
		nodes.append("transform = Transform3D(%s, %s, %s, %s)" % [basis, cx, height * 0.5, cz])
		nodes.append("")
		nodes.append('[node name="Mesh" type="MeshInstance3D" parent="Geometry/%s"]' % node_name)
		nodes.append("mesh = SubResource(\"%s\")" % mesh_id)
		nodes.append('surface_material_override/0 = SubResource("mat_wall")')
		nodes.append("")
		nodes.append('[node name="Col" type="CollisionShape3D" parent="Geometry/%s"]' % node_name)
		nodes.append("shape = SubResource(\"%s\")" % shape_id)
		nodes.append("")

	nodes.append('[node name="Furniture" type="Node3D" parent="."]')
	nodes.append("")

	var furn_i := 0
	for item: Dictionary in floorplan.get("furniture", []):
		furn_i += 1
		var cid: String = item["catalog_id"]
		var entry: Dictionary = catalog[cid]
		var rot: float = item.get("rot_y", 0.0)
		var pos: Array = item["pos"]
		var node_name := "%s_%d" % [cid.capitalize().replace(" ", ""), furn_i]

		nodes.append('[node name="%s" type="StaticBody3D" parent="Furniture"]' % node_name)
		nodes.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, 0, %s)" % [pos[0], pos[1]])
		nodes.append("")

		var scale: float = entry["scale"]
		var model_basis := _basis_lines(rot, scale)
		var rotated_offset := _rotate_xz(entry["model_offset"], rot)
		nodes.append('[node name="Model" parent="Furniture/%s" instance=ExtResource("%s")]' % [node_name, model_res_ids[cid]])
		nodes.append(
			"transform = Transform3D(%s, %s, %s, %s)"
			% [model_basis, rotated_offset.x, rotated_offset.y, rotated_offset.z]
		)
		nodes.append("")

		if entry.get("has_collision", false):
			var shape_id := "s_%s_%d" % [cid, furn_i]
			var size: Array = entry["collision_size"]
			sub_resources.append('[sub_resource type="BoxShape3D" id="%s"]' % shape_id)
			sub_resources.append("size = Vector3(%s, %s, %s)" % [size[0], size[1], size[2]])
			sub_resources.append("")

			var col_basis := _basis_lines(rot, 1.0)
			var offset: Array = entry.get("collision_offset", [0, 0, 0])
			var rotated_col_offset := _rotate_xz(offset, rot)
			nodes.append('[node name="Col" type="CollisionShape3D" parent="Furniture/%s"]' % node_name)
			nodes.append(
				"transform = Transform3D(%s, %s, %s, %s)"
				% [col_basis, rotated_col_offset.x, rotated_col_offset.y, rotated_col_offset.z]
			)
			nodes.append("shape = SubResource(\"%s\")" % shape_id)
			nodes.append("")

	if not floorplan.get("markers", []).is_empty():
		nodes.append('[node name="Markers" type="Node3D" parent="."]')
		nodes.append("")
		for marker: Dictionary in floorplan.get("markers", []):
			var pos: Array = marker["pos"]
			nodes.append('[node name="%s" type="Marker3D" parent="Markers"]' % marker["name"])
			nodes.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, 0.05, %s)" % [pos[0], pos[1]])
			nodes.append("")

	var doors: Array = floorplan.get("doors", [])
	if not doors.is_empty():
		ext_resources.append('[ext_resource type="Script" path="res://scripts/interaction/scene_door.gd" id="door_script"]')
		nodes.append('[node name="Doors" type="Node3D" parent="."]')
		nodes.append("")
		for door: Dictionary in doors:
			var pos: Array = door["pos"]
			sub_resources.append('[sub_resource type="BoxShape3D" id="s_door_%s"]' % door["name"])
			sub_resources.append("size = Vector3(1.0, 2.1, 1.0)")
			sub_resources.append("")
			nodes.append('[node name="%s" type="Area3D" parent="Doors"]' % door["name"])
			nodes.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, 1.1, %s)" % [pos[0], pos[1]])
			nodes.append('collision_layer = 2')
			nodes.append('collision_mask = 0')
			nodes.append('script = ExtResource("door_script")')
			nodes.append('prompt = "%s"' % door.get("prompt", "E — Door"))
			nodes.append('target_scene = "%s"' % door.get("target_scene", ""))
			nodes.append('target_marker = "%s"' % door.get("target_marker", ""))
			nodes.append("")
			nodes.append('[node name="Col" type="CollisionShape3D" parent="Doors/%s"]' % door["name"])
			nodes.append("shape = SubResource(\"s_door_%s\")" % door["name"])
			nodes.append("")

	var load_steps := ext_resources.size() + sub_resources.count("") + 1
	var out := "[gd_scene load_steps=%d format=3]\n\n" % load_steps
	out += "\n".join(ext_resources) + "\n\n"
	out += "\n".join(sub_resources) + "\n"
	out += "\n".join(nodes) + "\n"
	return out
