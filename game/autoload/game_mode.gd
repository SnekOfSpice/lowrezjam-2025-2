extends Node


enum Mode {
	Story,
	TimeAttack,
}

var mode : Mode


var highest_unlocked_level := 0

func initialize_mode(new_mode:Mode):
	mode = new_mode
