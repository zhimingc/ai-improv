extends Control

class Game:	
	func _init(_name, type):
		gameName = _name
		gamePace = type

	var gameName = ""
	var gamePace = PACE.FLEXIBLE

signal clock_start

enum PACE { SLOW, FAST, FLEXIBLE }
enum PROMPT_TYPE { EMOTION = 0, LOCATION, OCCUPATION, RELATIONSHIP, WORD }
enum GAMESTATE { IDLE, POST_GAME, SELECTION, PRE_GAME }

export var prompt_pool_size = 5
export var net_mode = false

var offlinePromptPaths = ["Prompts/prompt-emotion.txt", "Prompts/prompt-location.txt", "Prompts/prompt-occupation.txt", 
						"Prompts/prompt-relationship.txt", "Prompts/prompt-word.txt"]

# Short form games
var gameList = ["Toaster", "Forward, Reverse", "Questions Only", "Eye contact",
				"Whoosh", "Bad Dub", "Stand, sit, lie", "Character Swap",
				"Open Scenes", "One Syllable", "Causal Carousel"]
var games = []
var currentGame
var currentGameId = 0

var promptType = ""
var promptEnum = PROMPT_TYPE.EMOTION
var promptTypePool = [0, 1, 2, 3, 4]
var requesting = [false, false]

# tts variables
var queueSpeak = false
var gameTTS = ""
var promptTTS = ""

# timer
var clockReset = false

func init_games():
	games.append(Game.new("Toaster", PACE.SLOW))
	games.append(Game.new("Forward, Reverse", PACE.SLOW))
	games.append(Game.new("Questions Only", PACE.FAST))
	games.append(Game.new("Eye Contact", PACE.FLEXIBLE))
	games.append(Game.new("Whoosh", PACE.FLEXIBLE))
	games.append(Game.new("Bad Dub", PACE.FLEXIBLE))
	games.append(Game.new("Stand sit lie", PACE.FLEXIBLE))
	games.append(Game.new("Character Swap", PACE.SLOW))
	games.append(Game.new("Open Scenes", PACE.SLOW))
	games.append(Game.new("One Syllable", PACE.FAST))
	games.append(Game.new("Causal Carousel", PACE.SLOW))

func _ready():
	randomize()
	$HTTPRequest.connect("request_completed", self, "_on_prompt_request_completed")
	init_games()
	full_request()
	
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
	set_prompt_label(prompt)
	
func offline_prompt_request():
	yield(get_tree().create_timer(rand_range(0.5, 1.5)), "timeout")	
	var prompt = read_offline_prompt()
	set_prompt_label(prompt)
	
func read_offline_prompt():
	var file = File.new()
	var error = file.open(offlinePromptPaths[promptEnum], file.READ)
	var content = file.get_as_text()
	content = content.split("\n")
	var prompt = content[rand_range(0, content.size())]
	file.close()
	return prompt

func set_prompt_label(prompt):
	$ShowPanel2.set_word(prompt)
	$ShowPanel2.set_label("Prompt (" + promptType + ")")
	requesting[0] = false
	promptTTS = "Your prompt is " + promptType + ", " + prompt

func tts_speak(text):
	$tts.speak(text)

func _process(delta):
	if promptTypePool.size() > 0 and requesting[0] == false:
		if Input.is_action_just_pressed("new_prompt"):
			request_prompt(promptTypePool[rand_range(0, promptTypePool.size())])
			queueSpeak = true
	
	if Input.is_action_just_pressed("new_game"):
		get_rand_game()
		queueSpeak = true
		
	if clockReset:
		clockReset = false
		full_request()

	update_tts()

func full_request():
	request_prompt(promptTypePool[rand_range(0, promptTypePool.size())])
	get_rand_game()	
	queueSpeak = true

func get_rand_game():
	$ShowPanel.set_word("thinking...")
	$ShowPanel.set_label("")
	var nextGame = currentGameId
	while nextGame == currentGameId:
		nextGame = rand_range(0, games.size())
	requesting[1] = true
	
	yield(get_tree().create_timer(rand_range(0.5, 1.5)), "timeout")
	
	currentGameId = nextGame
	currentGame = games[nextGame]
	$ShowPanel.set_word(currentGame.gameName)
	$ShowPanel.set_label("Game")
	gameTTS = "Your next game is " + currentGame.gameName
	requesting[1] = false
	reset_clock()

func reset_clock():
	$ClockPanel.set_new_timer(currentGame)

func request_prompt(type):
	promptEnum = type
	promptType = str(PROMPT_TYPE.keys()[type]).to_lower()
	$ShowPanel2.set_word("thinking...")
	$ShowPanel2.set_label("")
	if net_mode:
		var result = $HTTPRequest.request("https://improbot.com/?key=" + promptType + "&n=" + str(prompt_pool_size) + "&lang=en")
	else:
		offline_prompt_request()
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
		yield(get_tree().create_timer(5.0), "timeout")
		emit_signal("clock_start")
	
func _on_debug_prompt_pressed(prompt):
	var index = promptTypePool.find(prompt)
	if index == -1:
		promptTypePool.append(prompt)
	else:
		promptTypePool.remove(index)


func _on_ClockPanel_timer_reset():
	clockReset = true

func _on_ClockPanel_timer_ending():
	$tts.speak("You have five seconds left.")
	
func _on_ClockPanel_show_over():
	$ShowPanel.set_word("")
	$ShowPanel.set_label("")
	$ShowPanel2.set_word("")
	$ShowPanel2.set_label("")
	$ClockPanel.clockActive = false
	$ClockPanel/ClockText.bbcode_text = "[center]Show Over"
	$tts.stop()
	$tts.speak("Show over, go home.")
	# yield(get_tree().create_timer(1.0), "timeout")
	# _on_ClockPanel_show_over()
	
