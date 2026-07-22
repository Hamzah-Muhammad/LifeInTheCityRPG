class_name StationKiosk
extends Interactable
## The subway map/kiosk: interacting opens the Station Select UI instead of
## starting dialogue.


func interact() -> void:
	StationManager.open()
