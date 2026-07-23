extends SceneTree
## Generates a 4-way street intersection (Jane & Finch) as a standalone .tscn,
## instanced as a child of jane_finch.tscn rather than hand-typed. Same safe
## pattern as generate_scene.gd: pure Transform3D math, writes plain .tscn
## text via FileAccess, never loads/instantiates the target scene.
##
## v3 (2026-07-23): the first two passes were wrong. v1 treated one
## road-straight tile as the whole street (too narrow). v2 guessed
## road-straight was a single LANE meant to be tiled side-by-side, and
## repeated it 7-wide - wrong, confirmed wrong by the user. Checking the
## pack's own Sample.png showed road-straight already depicts a complete
## road cross-section (lane markings both directions) in ONE tile - it
## needs to be scaled up, not repeated. Uses road-intersection.glb (not
## road-crossroad) for the center - same 1x1 footprint as road-straight.
## Sidewalks (tile-high/tile-slant) are a separate, independently-scaled
## piece positioned just outside the road edge, not on the same grid.
##
## v4 (2026-07-23): road tiles were rotated 90 degrees off (lane markings
## ran across the road instead of along it) - fixed. Per-direction arm
## lengths added (each arm reaches as far as the world's +-55m boundary
## allows from this intersection's off-center position, instead of one
## uniform short length) with a proper road-end cap at each terminus
## instead of an abrupt cut. Sidewalks get a grey concrete material
## override (was rendering white - the tile's own texture reference
## wasn't giving the expected result).
##
## Usage: godot --headless --path . --script tools/generate_streets.gd

const CATALOG_PATH := "res://leveldesign/city_catalog.json"
const OUT_PATH := "res://scenes/world/streets_jane_finch.tscn"

const ROAD_SCALE := 14.0     ## meters per road tile - road-straight/road-intersection already depict 2 lanes each direction in one tile (per Sample.png), scaled for ~3.5m/lane
const SIDEWALK_SCALE := 3.0  ## meters per sidewalk/curb tile - independent of ROAD_SCALE, these sit just outside the road edge
const CURB_Y_SCALE := 0.5    ## extra height reduction for sidewalk_high/sidewalk_slant - native 0.25m/0.27m read as too tall in-game
const LIGHT_INTERVAL := 12.0 ## meters between streetlights along the outer sidewalk edge
const LIGHT_SCALE := 7.5     ## light-curved.glb is only 0.675m tall natively (measured via measure_road_kit.gd) - nearly invisible next to a 14m road; scaled to a real ~5m streetlight height

const ROAD_HALF := ROAD_SCALE / 2.0
const CURB_OFFSET := ROAD_HALF + SIDEWALK_SCALE / 2.0
const SIDEWALK_OFFSET := ROAD_HALF + SIDEWALK_SCALE + SIDEWALK_SCALE / 2.0
const CORNER_NEAR := ROAD_HALF + SIDEWALK_SCALE / 2.0    ## corner-block tile center, near row
const CORNER_FAR := ROAD_HALF + SIDEWALK_SCALE * 1.5     ## corner-block tile center, far row
const SIDEWALK_START := ROAD_HALF + SIDEWALK_SCALE * 2.0 ## where each arm's sidewalk strip begins (past the corner box)

## Per-arm tile counts, chosen so ARM_REACH = ROAD_HALF + tiles*ROAD_SCALE stays
## inside the world's +-55m boundary given this intersection sits off-center
## at (-15, -10) (see jane_finch.tscn's StreetsJaneFinch transform) - West/South
## are capped by the boundary, East/North have more room so they run longer
## ("make the road continue" per user feedback 2026-07-23).
const ARM_TILES := {"N": 4, "S": 2, "E": 4, "W": 2}

# Arm direction data: axis ("x" or "z"), sign, tile rotation, end-cap rotation.
const ARMS := [
	{"name": "N", "axis": "z", "sign": 1.0, "road_rot": 90.0},
	{"name": "S", "axis": "z", "sign": -1.0, "road_rot": 90.0},
	{"name": "E", "axis": "x", "sign": 1.0, "road_rot": 0.0},
	{"name": "W", "axis": "x", "sign": -1.0, "road_rot": 0.0},
]


func _initialize() -> void:
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	if catalog.is_empty():
		quit(1)
		return

	var placements: Array[Dictionary] = []  # {catalog_id, x, z, rot_y, scale}
	var lights: Array[Dictionary] = []       # {x, z, rot_y}

	# Intersection center.
	placements.append({"catalog_id": "road_crossroad", "x": 0.0, "z": 0.0, "rot_y": 0.0, "scale": ROAD_SCALE})

	for arm: Dictionary in ARMS:
		var tiles: int = ARM_TILES[arm["name"]]
		var reach: float = ROAD_HALF + tiles * ROAD_SCALE
		_add_arm_road(placements, arm, tiles, reach)
		_add_arm_sidewalks(placements, lights, arm, reach)

	# Four corner sidewalk blocks (2x2 tiles each), where the two roads' sidewalk
	# zones meet - flat sidewalk, no curb ramp (kept simple, matches the lobby's
	# corner simplification). Plus one streetlight per corner - the arm-sidewalk
	# loop only starts placing lights past the corner box (first one ~24m down
	# each arm), so without this the intersection itself had zero streetlights,
	# which is exactly where the user was looking ("where's the streetlights").
	for sx in [1.0, -1.0]:
		for sz in [1.0, -1.0]:
			for cx in [CORNER_NEAR, CORNER_FAR]:
				for cz in [CORNER_NEAR, CORNER_FAR]:
					placements.append({"catalog_id": "sidewalk_high", "x": sx * cx, "z": sz * cz, "rot_y": 0.0, "scale": SIDEWALK_SCALE})
			lights.append({"x": sx * CORNER_FAR, "z": sz * CORNER_FAR, "rot_y": 0.0})

	var tscn_text := _build_tscn(catalog, placements, lights)
	var file := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if file == null:
		printerr("Could not open '%s' for writing (error %s)" % [OUT_PATH, FileAccess.get_open_error()])
		quit(1)
		return
	file.store_string(tscn_text)
	file.close()
	print("OK: wrote %s (%d tiles, %d streetlights)" % [OUT_PATH, placements.size(), lights.size()])
	quit(0)


func _pos_for(arm: Dictionary, along: float) -> Vector2:
	var d: float = arm["sign"] * along
	if arm["axis"] == "z":
		return Vector2(0.0, d)
	return Vector2(d, 0.0)


func _add_arm_road(placements: Array[Dictionary], arm: Dictionary, tiles: int, reach: float) -> void:
	for i in range(1, tiles + 1):
		var p := _pos_for(arm, i * ROAD_SCALE)
		placements.append({"catalog_id": "road_straight", "x": p.x, "z": p.y, "rot_y": arm["road_rot"], "scale": ROAD_SCALE})
	# End cap at the terminus, same rotation as the arm's road tiles.
	var end_p := _pos_for(arm, reach)
	placements.append({"catalog_id": "road_end", "x": end_p.x, "z": end_p.y, "rot_y": arm["road_rot"], "scale": ROAD_SCALE})


func _add_arm_sidewalks(placements: Array[Dictionary], lights: Array[Dictionary], arm: Dictionary, reach: float) -> void:
	var run_count := int(round((reach - SIDEWALK_START) / SIDEWALK_SCALE))
	for i in range(run_count):
		var along: float = SIDEWALK_START + (i + 0.5) * SIDEWALK_SCALE
		var p := _pos_for(arm, along)
		if arm["axis"] == "z":
			placements.append({"catalog_id": "sidewalk_slant", "x": CURB_OFFSET, "z": p.y, "rot_y": 0.0, "scale": SIDEWALK_SCALE})
			placements.append({"catalog_id": "sidewalk_slant", "x": -CURB_OFFSET, "z": p.y, "rot_y": 180.0, "scale": SIDEWALK_SCALE})
			placements.append({"catalog_id": "sidewalk_high", "x": SIDEWALK_OFFSET, "z": p.y, "rot_y": 0.0, "scale": SIDEWALK_SCALE})
			placements.append({"catalog_id": "sidewalk_high", "x": -SIDEWALK_OFFSET, "z": p.y, "rot_y": 0.0, "scale": SIDEWALK_SCALE})
		else:
			placements.append({"catalog_id": "sidewalk_slant", "x": p.x, "z": CURB_OFFSET, "rot_y": 90.0, "scale": SIDEWALK_SCALE})
			placements.append({"catalog_id": "sidewalk_slant", "x": p.x, "z": -CURB_OFFSET, "rot_y": 270.0, "scale": SIDEWALK_SCALE})
			placements.append({"catalog_id": "sidewalk_high", "x": p.x, "z": SIDEWALK_OFFSET, "rot_y": 0.0, "scale": SIDEWALK_SCALE})
			placements.append({"catalog_id": "sidewalk_high", "x": p.x, "z": -SIDEWALK_OFFSET, "rot_y": 0.0, "scale": SIDEWALK_SCALE})
		if int(round(along / SIDEWALK_SCALE)) % int(round(LIGHT_INTERVAL / SIDEWALK_SCALE)) == 0:
			if arm["axis"] == "z":
				lights.append({"x": SIDEWALK_OFFSET, "z": p.y, "rot_y": 0.0})
				lights.append({"x": -SIDEWALK_OFFSET, "z": p.y, "rot_y": 180.0})
			else:
				lights.append({"x": p.x, "z": SIDEWALK_OFFSET, "rot_y": 90.0})
				lights.append({"x": p.x, "z": -SIDEWALK_OFFSET, "rot_y": 270.0})


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
## xz_scale stretches the footprint; y_scale is kept at 1.0 unless overridden -
## these pieces' vertical proportions (curb height, slab thickness) were
## already realistic at native size.
func _basis_lines(rot_deg: float, xz_scale: float, y_scale: float = 1.0) -> String:
	var rad := deg_to_rad(rot_deg)
	var c := cos(rad) * xz_scale
	var s := sin(rad) * xz_scale
	return "%s, 0, %s, 0, %s, 0, %s, 0, %s" % [c, -s, y_scale, s, c]


func _build_tscn(catalog: Dictionary, placements: Array[Dictionary], lights: Array[Dictionary]) -> String:
	var ext_resources: Array[String] = []
	var sub_resources: Array[String] = []
	var nodes: Array[String] = []
	var model_res_ids: Dictionary = {}  # catalog_id -> "N_id"
	var res_counter := 1

	var all_ids := {}
	for p: Dictionary in placements:
		all_ids[p["catalog_id"]] = true
	if not lights.is_empty():
		all_ids["streetlight"] = true

	for cid: String in all_ids.keys():
		var entry: Dictionary = catalog[cid]
		var res_id := "%d_%s" % [res_counter, cid]
		res_counter += 1
		ext_resources.append('[ext_resource type="PackedScene" path="%s" id="%s"]' % [entry["model"], res_id])
		model_res_ids[cid] = res_id

	sub_resources.append('[sub_resource type="StandardMaterial3D" id="mat_sidewalk"]')
	sub_resources.append("albedo_color = Color(0.55, 0.55, 0.53, 1)")
	sub_resources.append("")

	nodes.append('[node name="StreetsJaneFinch" type="Node3D"]')
	nodes.append("")
	nodes.append('[node name="Tiles" type="Node3D" parent="."]')
	nodes.append("")

	var i := 0
	for p: Dictionary in placements:
		i += 1
		var cid: String = p["catalog_id"]
		var is_sidewalk := cid in ["sidewalk_high", "sidewalk_slant"]
		var y_scale: float = CURB_Y_SCALE if is_sidewalk else 1.0
		var basis := _basis_lines(p["rot_y"], p["scale"], y_scale)
		var node_name := "%s_%d" % [cid, i]
		nodes.append('[node name="%s" parent="Tiles" instance=ExtResource("%s")]' % [node_name, model_res_ids[cid]])
		nodes.append("transform = Transform3D(%s, %s, 0, %s)" % [basis, p["x"], p["z"]])
		if is_sidewalk:
			nodes.append('surface_material_override/0 = SubResource("mat_sidewalk")')
		nodes.append("")

	if not lights.is_empty():
		nodes.append('[node name="Streetlights" type="Node3D" parent="."]')
		nodes.append("")
		var li := 0
		for l: Dictionary in lights:
			li += 1
			var basis2 := _basis_lines(l["rot_y"], LIGHT_SCALE)
			nodes.append('[node name="Streetlight_%d" parent="Streetlights" instance=ExtResource("%s")]' % [li, model_res_ids["streetlight"]])
			nodes.append("transform = Transform3D(%s, %s, 0, %s)" % [basis2, l["x"], l["z"]])
			nodes.append("")

	var load_steps := ext_resources.size() + sub_resources.count("") + 1
	var out := "[gd_scene load_steps=%d format=3]\n\n" % load_steps
	out += "\n".join(ext_resources) + "\n\n"
	out += "\n".join(sub_resources) + "\n"
	out += "\n".join(nodes) + "\n"
	return out
