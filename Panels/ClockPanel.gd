extends TextureRect

export var startTime = 60.0

var currentTime = 0.0

func _ready():
	currentTime = startTime

func _process(delta):
	currentTime -= delta
	$ClockText.bbcode_text = "[center]" + String(currentTime).pad_decimals(0)
