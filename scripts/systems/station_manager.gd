extends Node
## Autoload "StationManager" — the TTC fast-travel map. Tracks which areas are
## unlocked and whether the Station Select UI should be showing. Mirrors the
## GameState/DialogueManager split: this holds state + signals, the UI scene
## (station_select_ui.gd) just renders it.
##
## Unlocking a new area later is just flipping `unlocked` to true and filling
## in scene/marker here — no UI changes needed.

signal opened
signal closed

var active: bool = false

const AREAS: Array[Dictionary] = [
	{
		"id": "jane_finch",
		"label": "Jane & Finch",
		"scene": "res://scenes/world/jane_finch.tscn",
		"marker": "SpawnFromSubway",
		"unlocked": true,
	},
	{"id": "scarborough", "label": "Scarborough", "scene": "", "marker": "", "unlocked": false},
	{"id": "downtown", "label": "Downtown", "scene": "", "marker": "", "unlocked": false},
]


func open() -> void:
	if active:
		return
	active = true
	opened.emit()


func close() -> void:
	if not active:
		return
	active = false
	closed.emit()


func travel(area_id: String) -> void:
	for area: Dictionary in AREAS:
		if area.get("id") == area_id and area.get("unlocked", false):
			close()
			SceneTransition.go(str(area.get("scene", "")), str(area.get("marker", "")))
			return
