extends Node
## Autoload "PauseManager" — the ESC-triggered pause overlay. Mirrors the
## GameState/DialogueManager/StationManager split: this holds state +
## signals, the UI scene (pause_menu.gd) just renders it. Movement/input
## freeze via the same `active`-flag convention already used for dialogue
## and station-select (see player.gd) rather than engine-level
## SceneTree.paused, so all three full-screen states behave consistently.

signal opened
signal closed

var active: bool = false


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


func toggle() -> void:
	if active:
		close()
	else:
		open()
