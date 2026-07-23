extends Node3D
## Fixed at a set point on the map (see each scene's instance transform) -
## deliberately NOT attached to the player. An earlier version rotated with
## the player, which made it useless for the thing it's meant to help with:
## reading off world/map coordinates (furniture placement, level design),
## which are fixed to the map, not the player's current facing.
## Toggle: SettingsManager.show_debug_axes (Options > Debug).

func _ready() -> void:
	visible = SettingsManager.show_debug_axes
	SettingsManager.show_debug_axes_changed.connect(func(enabled: bool) -> void: visible = enabled)
