extends TextureRect

signal timer_reset
signal timer_ending
signal show_over

export var debugTimer = false
export var totalTime = 300.0
export var startTime = 60.0
export var warningTime = 5.0
export var timeRange = [Vector2(60.0, 120.0), Vector2(180.0, 240.0)]

var timerBarObj
var currentTime = 0.0
var clockActive = true
var warned = false

func _ready():
	currentTime = startTime
	timerBarObj = get_parent().get_node("TimerBar")

func _process(delta):
	if (clockActive):
		currentTime -= delta
		timerBarObj.update_timebar(currentTime)
	
		if totalTime <= 0.0:
			emit_signal("show_over")
			totalTime = 0.0
		else:
			totalTime -= delta
			
		if currentTime <= 0.0:
			reset_timer()
			currentTime = 0.0
		if currentTime < warningTime and not warned:
			emit_signal("timer_ending")
			warned = true

	$ClockText.bbcode_text = "[center]" + String(currentTime/60).pad_decimals(0) + ":" + String(floor(fmod(currentTime, 60.0))).pad_decimals(0)
	$TotalTime.bbcode_text = "[center]" + String(totalTime/60).pad_decimals(0) + ":" + String(floor(fmod(totalTime, 60.0))).pad_decimals(0)

func set_new_timer(game):
	match game.gamePace:
		0:
			currentTime = rand_range(timeRange[0].x, timeRange[0].y)
		1:
			currentTime = rand_range(timeRange[1].x, timeRange[1].y)
		2:
			currentTime = rand_range(timeRange[0].x, timeRange[1].y)
	currentTime = stepify(currentTime, 5)
	clockActive = false
	warned = false

	if debugTimer:
		currentTime = 10
		clockActive = true
	
	timerBarObj.set_new_time(currentTime)
	
func reset_timer():
	emit_signal("timer_reset")
	clockActive = false

func _on_AIController_clock_start():
	clockActive = true
