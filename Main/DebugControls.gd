extends Control

var controller : Controller

# Called when the node enters the scene tree for the first time.
func _ready():
	controller = get_parent() 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("toggleDebug"):
		visible = !visible

	update_pacing_debug()

func update_pacing_debug():
	if controller == null:
		return

	var gamePace = ""
	if controller.currentGame:
		var timeRange = controller.get_node("ClockPanel").get_timeRange(controller.currentGame.gamePace)	
		gamePace = "Pace: " + str(Controller.PACE.keys()[controller.currentGame.gamePace])
		gamePace += "\nMin: " + str(timeRange.x) + "-" + str(timeRange.y)
	
	$PacingDebug/ShowPace.text = "Show Pace:\n" + str(Controller.SHOWPACE.keys()[controller.showPace])
	$PacingDebug/GamePace.text = gamePace
