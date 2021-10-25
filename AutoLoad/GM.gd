extends Node

var pc
var cam
var sm

signal play_sfx(sfx)
signal play_sfx_pitch(sfx, pitch)
signal start()

func _ready():
	randomize()

func set_pc(player):
	pc = player
	
func _process(delta):
	if pc == null:
		return
