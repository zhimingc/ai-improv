extends TextureRect

signal timer_reset
signal timer_ending
signal show_over

export var debugTimer = false
export var debugTime = 15.0
export var totalTime = 300.0
export var increasePace = 6.0
export var warningTime = 10.0
export var timeRange = [Vector2(60.0, 120.0), Vector2(180.0, 240.0)]

var timerBarObj
var currentTime = 0.0
var clockActive = false
var giveWarning = false

func _ready():
	totalTime *= 60
	increasePace *= 60
	currentTime = 10
	timerBarObj = get_parent().get_node("TimerBar")

func _process(delta):
	if (clockActive):
		currentTime -= delta
		timerBarObj.update_timebar(currentTime)
	
		if totalTime <= 0.0:
			totalTime = 0.0
			clockActive = false
			$ClockText.bbcode_text = ""
			$TotalTime.bbcode_text = "[center]0.0"
			emit_signal("show_over")
			return
		else:
			totalTime -= delta
			
		if currentTime <= 0.0:
			reset_timer()
		if currentTime < warningTime and giveWarning:
			giveWarning = false			
			emit_signal("timer_ending")

		$ClockText.bbcode_text = "[center]" + String(currentTime/60).pad_decimals(0) + ":" + String(floor(fmod(currentTime, 60.0))).pad_decimals(0)
		$TotalTime.bbcode_text = "[center]" + String(totalTime/60).pad_decimals(0) + ":" + String(floor(fmod(totalTime, 60.0))).pad_decimals(0)

func set_manual_timer(time):
	currentTime = time	
	timerBarObj.set_new_time(currentTime)
	clockActive = true

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
	giveWarning = true

	if debugTimer:
		currentTime = debugTime
		clockActive = true
	
	timerBarObj.set_new_time(currentTime)
	
func zero_timer():
	currentTime = 0.0
	
func reset_timer():
	clockActive = false	
	currentTime = 0.0			
	emit_signal("timer_reset")

func _on_AIController_clock_start():
	clockActive = true
