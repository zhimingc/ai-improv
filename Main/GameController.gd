extends Control

enum PROMPT_TYPE { EMOTION, LOCATION, OCCUPATION, RELATIONSHIP }

# Short form games
var gameList = ["Toaster", "Forward, Reverse", "Questions Only", "Eye contact",
				"Whoosh", "Bad Dub (Gibberish)", "Stand, sit, lie", "Character Swap"]

export var prompt_pool_size = 5

var promptType
var promptTypePool = [0, 1, 2, 3]
var requesting = [false, false]

# tts variables
var queueSpeak = false
var gameTTS = ""
var promptTTS = ""

var currentGame = 0

func _ready():
	$HTTPRequest.connect("request_completed", self, "_on_prompt_request_completed")

func _on_prompt_request_completed(result, response_code, headers, body):
	var xml = XMLParser.new()
	var xmlError = xml.open_buffer(body)
	var xmlRead = 0
	while xmlRead == 0:
		xmlRead = xml.read()
		match xml.get_node_type():
			XMLParser.NODE_ELEMENT:
				if xml.get_node_name() == "textarea":
					xml.read()
					break

	var prompts = xml.get_node_data().split("\n")
	var prompt = prompts[rand_range(0, prompts.size())]
	$ShowPanel2.set_word(prompt)
	$ShowPanel2.set_label("Prompt (" + promptType + ")")
	requesting[0] = false
	promptTTS = "Your prompt is " + promptType + ", " + prompt

func tts_speak(text):
	$tts.speak(text)

func _process(delta):
	if Input.is_action_just_pressed("new_prompt") and promptTypePool.size() > 0 and requesting[0] == false:
		request_prompt(promptTypePool[rand_range(0, promptTypePool.size())])
		queueSpeak = true
	
	if Input.is_action_just_pressed("new_game"):
		get_rand_game()
		queueSpeak = true
		
	update_tts()

func get_rand_game():
	$ShowPanel.set_word("thinking...")
	$ShowPanel.set_label("")
	var nextGame = currentGame
	while nextGame == currentGame:
		nextGame = rand_range(0, gameList.size())
	requesting[1] = true
	
	yield(get_tree().create_timer(rand_range(0.5, 1.5)), "timeout")
	$ShowPanel.set_word(gameList[nextGame])
	$ShowPanel.set_label("Game")
	gameTTS = "Your next game is " + gameList[nextGame]
	requesting[1] = false

func request_prompt(type):
	promptType = str(PROMPT_TYPE.keys()[type]).to_lower()
	var result = $HTTPRequest.request("https://improbot.com/?key=" + promptType + "&n=" + str(prompt_pool_size) + "&lang=en")
	$ShowPanel2.set_word("thinking...")
	$ShowPanel2.set_label("")
	requesting[0] = true

func update_tts():
	if not queueSpeak:
		return
	var canSpeak = true
	for request in requesting:
		if request == true:
			canSpeak = false
			
	if canSpeak:
		$tts.speak(gameTTS + " and " + promptTTS)
		queueSpeak = false
	
func _on_debug_prompt_pressed(prompt):
	var index = promptTypePool.find(prompt)
	if index == -1:
		promptTypePool.append(prompt)
	else:
		promptTypePool.remove(index)
