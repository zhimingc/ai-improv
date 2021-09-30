extends TextureRect

signal timer_reset

export var startTime = 60.0
export var timeRange = Vector2(5.0, 10.0)

var currentTime = 0.0

func _ready():
	currentTime = startTime

func _process(delta):
	currentTime -= delta
	$ClockText.bbcode_text = "[center]" + String(currentTime).pad_decimals(0)

	if currentTime <= 0.0:
		reset_timer()

func reset_timer():
	currentTime = rand_range(timeRange.x, timeRange.y)
	emit_signal("timer_reset")
