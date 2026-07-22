extends Node
## Autoload "GameState" — the hidden numbers behind Malik's story.
##
## Four stats are tracked across the whole game and decide the ending:
##   rep     — street reputation. Opens doors, attracts enemies.
##   heat    — police + rival attention. Too high and things go wrong.
##   loyalty — how solid Malik is with the people who knew him first.
##   cash    — money in pocket.
## Story flags record one-off events ("texted_ty", "checked_phone", ...).

signal stat_changed(stat: String, value: int)
signal flag_set(flag: String)

const STATS: Array[String] = ["rep", "heat", "loyalty", "cash"]

var rep: int = 0
var heat: int = 0
var loyalty: int = 0
var cash: int = 40

var flags: Dictionary = {}


func adjust(stat: String, amount: int) -> void:
	if stat not in STATS:
		push_warning("GameState.adjust: unknown stat '%s'" % stat)
		return
	set(stat, int(get(stat)) + amount)
	stat_changed.emit(stat, int(get(stat)))


func set_flag(flag: String) -> void:
	flags[flag] = true
	flag_set.emit(flag)


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


func reset() -> void:
	rep = 0
	heat = 0
	loyalty = 0
	cash = 40
	flags.clear()
