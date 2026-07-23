extends SceneTree
## Read-only measurement script - loads a few key City Kit Roads / Commercial
## pieces, prints their AABB size, and quits. Never saves anything.
## Usage: godot --headless --path . --script tools/measure_road_kit.gd

const MODELS := [
	"res://assets/kenney_city_kit_roads/models/road-straight.glb",
	"res://assets/kenney_city_kit_roads/models/road-crossroad.glb",
	"res://assets/kenney_city_kit_roads/models/road-intersection.glb",
	"res://assets/kenney_city_kit_roads/models/road-intersection-path.glb",
	"res://assets/kenney_city_kit_roads/models/road-square.glb",
	"res://assets/kenney_city_kit_roads/models/road-side.glb",
	"res://assets/kenney_city_kit_roads/models/road-end.glb",
	"res://assets/kenney_city_kit_roads/models/road-end-round.glb",
	"res://assets/kenney_city_kit_roads/models/light-square.glb",
	"res://assets/kenney_city_kit_roads/models/light-curved.glb",
	"res://assets/kenney_city_kit_roads/models/sign-highway.glb",
	"res://assets/kenney_city_kit_roads/models/road-bend.glb",
	"res://assets/kenney_car_kit/models/sedan.glb",
	"res://assets/kenney_car_kit/models/taxi.glb",
	"res://assets/kenney_city_kit_roads/models/tile-high.glb",
	"res://assets/kenney_city_kit_roads/models/tile-low.glb",
	"res://assets/kenney_city_kit_roads/models/tile-slant.glb",
	"res://assets/kenney_city_kit_commercial/models/building-skyscraper-a.glb",
	"res://assets/kenney_city_kit_commercial/models/building-skyscraper-b.glb",
	"res://assets/kenney_city_kit_commercial/models/building-skyscraper-c.glb",
	"res://assets/kenney_city_kit_commercial/models/building-skyscraper-d.glb",
	"res://assets/kenney_city_kit_commercial/models/building-j.glb",
	"res://assets/kenney_city_kit_commercial/models/building-k.glb",
	"res://assets/kenney_city_kit_commercial/models/building-i.glb",
	"res://assets/kenney_city_kit_commercial/models/building-l.glb",
	"res://assets/kenney_city_kit_commercial/models/building-m.glb",
	"res://assets/kenney_city_kit_commercial/models/building-n.glb",
]


func _initialize() -> void:
	for path: String in MODELS:
		if not ResourceLoader.exists(path):
			print("MISSING: %s" % path)
			continue
		var scene: PackedScene = load(path)
		var inst: Node3D = scene.instantiate()
		root.add_child(inst)
		var aabb := AABB()
		var first := true
		for child in inst.find_children("*", "MeshInstance3D", true, false):
			var mesh_inst: MeshInstance3D = child
			var mesh_aabb: AABB = mesh_inst.mesh.get_aabb()
			var xform: Transform3D = mesh_inst.transform
			var world_aabb: AABB = xform * mesh_aabb
			if first:
				aabb = world_aabb
				first = false
			else:
				aabb = aabb.merge(world_aabb)
		print("%s -> size=%s  min=%s  max=%s" % [path.get_file(), aabb.size, aabb.position, aabb.end])
		inst.queue_free()
	quit(0)
