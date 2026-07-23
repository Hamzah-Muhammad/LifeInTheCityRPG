class_name TrafficCar
extends Node3D
## Ambient background traffic - drives forward along its own +Z axis at a
## constant speed and loops back to its start once it's traveled
## loop_distance. Visual only, no collision with the player.
##
## +Z, not Godot's usual -Z-forward: verified via tools/inspect_model.gd on
## sedan.glb - wheel-front-*/wheel-back-* sit at local z=+0.66/-0.66, so this
## Car Kit pack's models are authored front-at-+Z (same glTF-vs-Godot forward
## mismatch as Malik's rig, see project memory Gotchas - checked this time
## instead of guessing after the car drove backward on the first attempt).

@export var speed: float = 9.0
@export var loop_distance: float = 60.0

var _start_position: Vector3


func _ready() -> void:
	_start_position = position


func _physics_process(delta: float) -> void:
	translate(Vector3(0, 0, speed * delta))
	if position.distance_to(_start_position) > loop_distance:
		position = _start_position
