extends TextureRect

var originTime
var originScale

export(Array, Color, RGBA) var colors

func _ready():
	originScale = rect_scale

func set_new_time(time):
	originTime = time
	rect_scale = originScale

func update_timebar(time):
	if originTime:
		rect_scale.y = time / originTime * originScale.y

func set_timer_color(id):
	self_modulate = colors[id]
