extends TextureRect

signal timer_reset

export var startTime = 60.0
export var timeRange = Vector2(5.0, 10.0)

var currentTime = 0.0
var clockActive = true

func _ready():
	currentTime = startTime

func _process(delta):
	if (clockActive):
		currentTime -= delta

	if currentTime <= 0.0:
		reset_timer()

	$ClockText.bbcode_text = "[center]" + String(ceil(currentTime)).pad_decimals(0)

func reset_timer():
	currentTime = rand_range(timeRange.x, timeRange.y)
	emit_signal("timer_reset")
	clockActive = false

func _on_AIController_clock_start():
	clockActive = true
