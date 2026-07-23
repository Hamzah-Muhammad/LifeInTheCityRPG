extends SceneTree
## Scatters 20+ background highrise apartment towers across the Jane & Finch
## plaza, avoiding the road corridor, the subway kiosk, the 3 named
## buildings (Tower/BuildingB/BuildingC), and the world boundary. Same safe
## pattern as generate_scene.gd/generate_streets.gd: pure math, writes plain
## .tscn text, never loads/instantiates the target scene.
##
## Usage: godot --headless --path . --script tools/generate_highrises.gd

const CATALOG_PATH := "res://leveldesign/highrise_catalog.json"
const OUT_PATH := "res://scenes/world/highrises_jane_finch.tscn"

const RNG_SEED := 20260723
const TARGET_COUNT := 28
const GRID_STEP := 7.0       ## candidate spacing before jitter/filtering - dense grid needed since the road-cross + existing-building exclusions eat most of a sparse one
const JITTER := 2.0          ## +-meters of random offset per candidate
const WORLD_HALF := 55.0
const BOUNDARY_MARGIN := 4.0 ## stay this far inside the +-55 boundary walls
const MIN_HEIGHT := 22.0
const MAX_HEIGHT := 35.0
const MIN_SEPARATION := 1.0  ## extra gap required between any two highrise footprints - real Jane & Finch towers sit close together, keep this small

# Streets sub-scene offset (see jane_finch.tscn's StreetsJaneFinch transform).
# Half-width is just past the actual paved+sidewalk extent (SIDEWALK_OFFSET=11.5
# in generate_streets.gd), not generously padded - the first pass excluded too
# much of the map this way, see DEBUG counts.
const ROAD_CENTER := Vector2(-15.0, -10.0)
const ROAD_EXCLUDE_HALF := 12.0

# Subway kiosk/canopy area (see StationCanopy/StationPillarA-D in jane_finch.tscn).
const KIOSK_MIN := Vector2(-6.0, -1.0)
const KIOSK_MAX := Vector2(6.0, 9.0)

# Existing named buildings: {center, exclude_radius} - tightened to their real
# measured footprint + a small buffer, not generously padded (see DEBUG counts).
const EXISTING_BUILDINGS := [
	{"center": Vector2(-32.0, -28.0), "radius": 9.0},   # Tower (real footprint ~10.5x11.4)
	{"center": Vector2(28.0, -30.0), "radius": 19.0},   # BuildingB (real footprint ~34.4x22.1)
	{"center": Vector2(30.0, 22.0), "radius": 16.0},    # BuildingC (real footprint ~29.8x13.5)
]


func _initialize() -> void:
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	if catalog.is_empty():
		quit(1)
		return

	seed(RNG_SEED)
	var catalog_ids: Array = []
	for k in catalog.keys():
		if typeof(catalog[k]) == TYPE_DICTIONARY:
			catalog_ids.append(k)

	var placed: Array[Dictionary] = []  # {catalog_id, x, z, scale, footprint_radius}
	var candidates := _build_candidates()
	candidates.shuffle()
	var excluded_count := 0
	var overlap_reject_count := 0
	print("DEBUG: %d raw candidates" % candidates.size())

	for c: Vector2 in candidates:
		if placed.size() >= TARGET_COUNT:
			break
		if _in_excluded_zone(c):
			excluded_count += 1
			continue

		var cid: String = catalog_ids[randi() % catalog_ids.size()]
		var entry: Dictionary = catalog[cid]
		var target_h: float = randf_range(MIN_HEIGHT, MAX_HEIGHT)
		var scale: float = target_h / float(entry["native_h"])
		var half_w: float = float(entry["native_w"]) * scale * 0.5
		var half_d: float = float(entry["native_d"]) * scale * 0.5
		var footprint_radius: float = Vector2(half_w, half_d).length()

		var overlaps := false
		for p: Dictionary in placed:
			if c.distance_to(Vector2(p["x"], p["z"])) < footprint_radius + p["footprint_radius"] + MIN_SEPARATION:
				overlaps = true
				break
		if overlaps:
			overlap_reject_count += 1
			continue

		placed.append({
			"catalog_id": cid, "x": c.x, "z": c.y, "scale": scale,
			"rot_y": [0.0, 90.0, 180.0, 270.0][randi() % 4],
			"footprint_radius": footprint_radius,
		})

	var tscn_text := _build_tscn(catalog, placed)
	var file := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if file == null:
		printerr("Could not open '%s' for writing (error %s)" % [OUT_PATH, FileAccess.get_open_error()])
		quit(1)
		return
	file.store_string(tscn_text)
	file.close()
	print("DEBUG: excluded=%d overlap_rejected=%d placed=%d" % [excluded_count, overlap_reject_count, placed.size()])
	print("OK: wrote %s (%d highrises placed, target was %d)" % [OUT_PATH, placed.size(), TARGET_COUNT])
	quit(0)


func _build_candidates() -> Array:
	var out: Array = []
	var half := WORLD_HALF - BOUNDARY_MARGIN
	var x := -half
	while x <= half:
		var z := -half
		while z <= half:
			var jx: float = x + randf_range(-JITTER, JITTER)
			var jz: float = z + randf_range(-JITTER, JITTER)
			out.append(Vector2(jx, jz))
			z += GRID_STEP
		x += GRID_STEP
	return out


func _in_excluded_zone(p: Vector2) -> bool:
	if absf(p.x - ROAD_CENTER.x) < ROAD_EXCLUDE_HALF or absf(p.y - ROAD_CENTER.y) < ROAD_EXCLUDE_HALF:
		return true
	if p.x > KIOSK_MIN.x and p.x < KIOSK_MAX.x and p.y > KIOSK_MIN.y and p.y < KIOSK_MAX.y:
		return true
	for b: Dictionary in EXISTING_BUILDINGS:
		if p.distance_to(b["center"]) < b["radius"]:
			return true
	return false


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


## Matches Basis().rotated(Vector3.UP, angle) - verified convention, see project memory Gotchas.
func _basis_lines(rot_deg: float, scale: float) -> String:
	var rad := deg_to_rad(rot_deg)
	var c := cos(rad) * scale
	var s := sin(rad) * scale
	return "%s, 0, %s, 0, %s, 0, %s, 0, %s" % [c, -s, scale, s, c]


func _build_tscn(catalog: Dictionary, placed: Array[Dictionary]) -> String:
	var ext_resources: Array[String] = []
	var sub_resources: Array[String] = []
	var nodes: Array[String] = []
	var model_res_ids: Dictionary = {}
	var res_counter := 1

	var used_ids := {}
	for p: Dictionary in placed:
		used_ids[p["catalog_id"]] = true
	for cid: String in used_ids.keys():
		var entry: Dictionary = catalog[cid]
		var res_id := "%d_%s" % [res_counter, cid]
		res_counter += 1
		ext_resources.append('[ext_resource type="PackedScene" path="%s" id="%s"]' % [entry["model"], res_id])
		model_res_ids[cid] = res_id

	nodes.append('[node name="HighrisesJaneFinch" type="Node3D"]')
	nodes.append("")

	var i := 0
	for p: Dictionary in placed:
		i += 1
		var cid: String = p["catalog_id"]
		var entry: Dictionary = catalog[cid]
		var scale: float = p["scale"]
		var w: float = float(entry["native_w"]) * scale
		var h: float = float(entry["native_h"]) * scale
		var d: float = float(entry["native_d"]) * scale
		var body_name := "%s_%d" % [cid, i]
		var shape_id := "s_%s" % body_name

		sub_resources.append('[sub_resource type="BoxShape3D" id="%s"]' % shape_id)
		sub_resources.append("size = Vector3(%s, %s, %s)" % [w, h, d])
		sub_resources.append("")

		nodes.append('[node name="%s" type="StaticBody3D" parent="."]' % body_name)
		nodes.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, 0, %s)" % [p["x"], p["z"]])
		nodes.append("")
		var basis := _basis_lines(p["rot_y"], scale)
		nodes.append('[node name="Model" parent="%s" instance=ExtResource("%s")]' % [body_name, model_res_ids[cid]])
		nodes.append("transform = Transform3D(%s, 0, 0, 0)" % basis)
		nodes.append("")
		nodes.append('[node name="Col" type="CollisionShape3D" parent="%s"]' % body_name)
		nodes.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, %s, 0)" % (h * 0.5))
		nodes.append("shape = SubResource(\"%s\")" % shape_id)
		nodes.append("")

	var load_steps := ext_resources.size() + sub_resources.count("") + 1
	var out := "[gd_scene load_steps=%d format=3]\n\n" % load_steps
	out += "\n".join(ext_resources) + "\n\n"
	out += "\n".join(sub_resources) + "\n"
	out += "\n".join(nodes) + "\n"
	return out
