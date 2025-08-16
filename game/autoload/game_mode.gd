extends Node

const LEVELS := [
	"utah",
	"caledon",
	"redonda",
	"cathedral city fire station",
	"moraine lake",
	"oregon",
	"islamabad chand tara monument",
	"irkutsk",
	"santorini",
	"kiyomizu-dera",
	"pitt meadows",
]


enum Mode {
	Story,
	TimeAttack,
}

var mode : Mode
const SAVEGAME_PATH := "user://savegame.cfg"

var highest_unlocked_level := 0

func _ready() -> void:
	var config = ConfigFile.new()

	var err = config.load(SAVEGAME_PATH)

	if err != OK: # no savegame
		return

	highest_unlocked_level = config.get_value("progress", "highest_unlocked_level", highest_unlocked_level)

func save() -> void:
	var config = ConfigFile.new()
	config.set_value("progress", "highest_unlocked_level", highest_unlocked_level)
	config.save(SAVEGAME_PATH)

func set_highest_unlocked_level(value:int):
	highest_unlocked_level = value
	save()

func initialize_mode(new_mode:Mode):
	mode = new_mode
