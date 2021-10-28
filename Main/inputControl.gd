extends Control


var input_path = "res://Input/input.json"
var json_data : JSONParseResult

var emotionKey = "pleaseEnterAnEmotionBelow"
var locationKey = "pleaseEnterALocationBelow"
var occupationKey = "pleaseEnterAnOccupationBelow"
var wordKey = "pleaseEnterAny34SyllableWordsBelow"

var emotions = []
var locations = []
var occupations = []
var words = []

# Called when the node enters the scene tree for the first time.
func _ready():
	# read json file
	var file = File.new()
	file.open(input_path, file.READ)
	var json_text = file.get_as_text()
	json_data = JSON.parse(json_text)
	print("JSON read result: " + json_data.error_string)
	
	# init prompt arrays
	for data in json_data.result:
		if data.has(emotionKey):
			emotions.append(data[emotionKey])
		if data.has(locationKey):
			locations.append(data[locationKey])
		if data.has(occupationKey):
			occupations.append(data[occupationKey])
		if data.has(wordKey):
			words.append(data[wordKey])

	# randomise prompts
	emotions.shuffle()
	locations.shuffle()
	occupations.shuffle()
	words.shuffle()

func get_prompt_from_input(type = Controller.PROMPT_TYPE.EMOTION):
	# if type == Controller.PROMPT_TYPE.DEFAULT:
	#	type = Controller.PROMPT_TYPE.values()[rand_range(0, Controller.PROMPT_TYPE.values().size())]
	match type:
		Controller.PROMPT_TYPE.EMOTION:
			if emotions.size() > 0:
				return emotions.pop_back()
		Controller.PROMPT_TYPE.LOCATION:
			if locations.size() > 0:
				return locations.pop_back()
		Controller.PROMPT_TYPE.OCCUPATION:
			if occupations.size() > 0:
				return occupations.pop_back()
		Controller.PROMPT_TYPE.WORD:
			if words.size() > 0:
				return words.pop_back()

	return ""
