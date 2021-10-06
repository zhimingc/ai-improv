extends TextureRect

var originTime
var originScale

func _ready():
	originScale = rect_scale

func set_new_time(time):
	originTime = time
	rect_scale = originScale

func update_timebar(time):
	if originTime:
		rect_scale.y = time / originTime * originScale.y
