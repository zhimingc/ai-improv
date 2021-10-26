extends TextureRect

signal timer_reset
signal timer_ending
signal show_over

export var demo = false
export var debugTimer = false
export var debugTime = 15.0
export var totalTime = 30.0
export var increasePace = 6.0
export var warningTime = 15.0
export var endGameBufferTime = 60.0

var controller : Controller
var timeRange
var timeElapsed = 0.0
var timerBarObj
var currentClockObj
var currentTime = 0.0
var clockActive = false
var giveWarning = false
var pacings = []
var currentPacing
var lastGame = false
var showOver = false

func _ready():
	if demo:
		totalTime = 0.5
	totalTime *= 60
	increasePace *= 60
	currentTime = 10
	controller = get_parent()	
	timerBarObj = controller.get_node("TimerBar")
	timeRange = controller.timeRange
	init_pace_shift_times()
	currentPacing = pacings.pop_front()
	
func init_pace_shift_times():
	pacings.append_array(controller.pacing)
	var accTime = 0.0
	for pace in pacings:
		var time = totalTime * (pace.timePerc / 100.0)
		accTime += time
		pace.timeShift = accTime

func set_clock_active(flag):
	clockActive = flag

func _process(delta):
	if (clockActive):
		currentTime -= delta
		totalTime -= delta
		timeElapsed += delta		
		timerBarObj.update_timebar(currentTime)
	
		if not showOver:
			if totalTime <= 0.0:
				totalTime = 0.0
				# set_clock_active(false)
				$ClockText.bbcode_text = ""
				$TotalTime.bbcode_text = "[center]0.0"
				emit_signal("show_over")
				showOver = true
			if not lastGame:
				check_pace_shift()
			if currentTime < warningTime and giveWarning and !showOver:
				giveWarning = false			
				emit_signal("timer_ending")
			
		if currentTime <= 0.0:
			reset_timer()

		currentClockObj.bbcode_text = "[center]" + String(currentTime/60).pad_decimals(0) + ":" + get_padded_time(floor(fmod(currentTime, 60.0)))
		$TotalTime.bbcode_text = "[center]" + String(totalTime/60).pad_decimals(0) + ":" + get_padded_time(floor(fmod(totalTime, 60.0)))

func check_pace_shift():
	if currentPacing == null:
		return
	if timeElapsed >= currentPacing.timeShift:
		currentPacing = pacings.pop_front()
		if currentPacing == null:
			return
		controller.set_pace_state(currentPacing.pace)		

func get_padded_time(time):
	if time < 10:
		return "0" + String(time).pad_decimals(0)
	return String(time).pad_decimals(0)	

func set_clockObj(obj):
	currentClockObj = obj

func set_visible(vis):
	$ClockText.visible = vis
	$TotalTime.visible = vis

func set_manual_timer(time):
	currentTime = time	
	timerBarObj.set_new_time(currentTime)
	set_clock_active(true)

func set_new_timer(pace):
	var curTimeRange = get_timeRange(pace)
	currentTime = rand_range(curTimeRange.x, curTimeRange.y)
	currentTime *= 60
	currentTime = stepify(currentTime, 5)
	
	# add remaining time if show is about to end
	var timeAfterGame = totalTime - currentTime
	if timeAfterGame < endGameBufferTime:
		currentTime = totalTime
		lastGame = true
	
	set_clock_active(false)
	giveWarning = true

	if debugTimer:
		currentTime = debugTime
		set_clock_active(true)
	
	timerBarObj.set_new_time(currentTime)

func get_time_left():
	var timeLeft = [floor(currentTime/60), floor(fmod(currentTime, 60.0))]
	return timeLeft
	
func get_timeRange(pace):
	match pace:
		0: # fast
			return Vector2(timeRange[0].x, timeRange[0].y)
		1: # mid
			return Vector2(timeRange[1].x, timeRange[1].y)
		2: # fast
			return Vector2(timeRange[2].x, timeRange[2].y)
		3: # v fast
			return Vector2(timeRange[3].x, timeRange[3].y)
		4: # flex slow
			return Vector2(timeRange[1].y, timeRange[2].y)
	
func zero_timer():
	currentTime = 0.0
	set_clock_active(true)
	
func reset_timer():
	set_clock_active(false)
	currentTime = 0.0		
	emit_signal("timer_reset")

func _on_AIController_clock_start():
	set_clock_active(true)
