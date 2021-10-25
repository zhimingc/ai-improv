extends Camera2D

export var shakeFreq = 1
export var shakeForce = [ 2, 3 ]

var timer = 0.0
var freq = 0
var shakeMin = 0
var shakeDelta = 0
var shakeTarget = Vector2()

func _ready():
	gm.cam = self
	shakeMin = shakeForce[0]
	shakeDelta = shakeForce[1] - shakeForce[0]

func _process(delta):
	update_shake_cam(delta)

func trigger_shake_cam(time):
	if timer <= 0:
		timer = time
	
func shake_dir():
	return 1 if randi() % 2 == 1 else -1

func update_shake_cam(delta):
	if timer > 0:
		timer -= delta
		shake_from_origin()
		# shake_to_target(delta)
	else:
		set_offset(Vector2(0, 0))		

func get_shake_pos():
	var shakeAmt = Vector2(shakeMin + randi() % shakeDelta, shakeMin + randi() % shakeDelta)
	shakeAmt *= Vector2(shake_dir(), shake_dir())
	return shakeAmt

func shake_to_target(delta):
	var speed = 50
	var toTarget = shakeTarget - get_offset()
	if (toTarget).length() <= 0.1:
		shakeTarget = get_shake_pos()
	else:
		set_offset(get_offset() + toTarget.normalized() * delta * speed)
	
func shake_from_origin():
	freq += 1
	if freq % shakeFreq == 0:
		var shakeAmt = get_shake_pos()
		set_offset(shakeAmt)
		freq = 0
