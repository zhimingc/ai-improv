extends Control

signal clock_start

enum PACE { SLOW, FAST, FLEXIBLE }
enum PROMPT_TYPE { EMOTION = 0, LOCATION, OCCUPATION, RELATIONSHIP, WORD }
enum GAMESTATE { PRE_SHOW, IN_GAME, POST_GAME, SELECTION, PRE_GAME, POST_SHOW }

class Game:	
	var GAME_REQ = ["a bell", "chairs"]
	
	func _init(_name, type, reqs = []):
		gameName = _name
		gamePace = type
		for req in reqs:
			if req <= GAME_REQ.size():
				requirements.append(GAME_REQ[req])

	var gameName = ""
	var gamePace = PACE.FLEXIBLE
	var requirements = []

export var prompt_pool_size = 5
export var net_mode = false

var offlinePromptPaths = ["Prompts/prompt-emotion.txt", "Prompts/prompt-location.txt", "Prompts/prompt-occupation.txt", 
						"Prompts/prompt-relationship.txt", "Prompts/prompt-word.txt"]

# state machine
var currentState = GAMESTATE.PRE_SHOW

# Short form games
var gameList = ["Toaster", "Forward, Reverse", "Questions Only", "Eye contact",
				"Whoosh", "Bad Dub", "Stand, sit, lie", "Character Swap",
				"Open Scenes", "One Syllable", "Causal Carousel"]
var games = []
var originalGames = []
var currentGame
var currentGameId = 0

var promptType = ""
var promptLabel = []
var promptEnum = PROMPT_TYPE.EMOTION
var promptTypePool = [0, 1, 2, 3, 4]

# tts variables
var gameTTS = ""
var promptTTS = ""
var speakQueue = []

# timer
var clockReset = false

func init_games():
	games.append(Game.new("Toaster", PACE.SLOW, [0, 1]))
	games.append(Game.new("Forward, Reverse", PACE.SLOW, [0]))
	games.append(Game.new("Questions Only", PACE.FAST, []))
	games.append(Game.new("Eye Contact", PACE.FLEXIBLE, [0]))
	games.append(Game.new("Whoosh", PACE.FLEXIBLE))
	games.append(Game.new("Bad Dub", PACE.FLEXIBLE))
	games.append(Game.new("Stand sit lie", PACE.FLEXIBLE))
	games.append(Game.new("Character Swap", PACE.SLOW, [0]))
	games.append(Game.new("Open Scenes", PACE.SLOW))
	games.append(Game.new("One Syllable", PACE.FAST))
	games.append(Game.new("Alphabet", PACE.FAST))
	games.append(Game.new("Change, +1, More", PACE.FLEXIBLE, [0]))
	# games.append(Game.new("Causal Carousel", PACE.SLOW))
	# games.append(Game.new("Blind Lines", PACE.SLOW))
	originalGames = games

func reset_game_list():
	games = originalGames

func remove_game(index):
	games.remove(index)
	if games.size() == 0:
		reset_game_list()

func _ready():
	randomize()
	$HTTPRequest.connect("request_completed", self, "_on_prompt_request_completed")
	init_games()
	set_state(GAMESTATE.PRE_SHOW)

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
	# yield(get_tree().create_timer(rand_range(0.5, 1.5)), "timeout")	
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
	promptLabel = [prompt, "Prompt (" + promptType + ")"]
	promptTTS = "Your prompt is " + prompt	

func give_prompt():
	set_game_texts($ShowPanel2, promptLabel)	
	speakQueue.append(promptTTS)

func get_rand_game():
	set_game_texts($ShowPanel, ["thinking...", ""])
	
	var nextGame = currentGameId
	while nextGame == currentGameId:
		nextGame = rand_range(0, games.size())
	
	yield(get_tree().create_timer(rand_range(0.25, 0.5)), "timeout")
	
	currentGameId = nextGame
	currentGame = games[nextGame]
	remove_game(nextGame)
	$ShowPanel.set_word(currentGame.gameName)
	$ShowPanel.set_label("Game")
	set_game_texts($ShowPanel, [currentGame.gameName, "Game"])
	gameTTS = "Your next game is " + currentGame.gameName + ". "
	if currentGame.requirements.size() > 0:
		var reqs = "You will need "
		for req in currentGame.requirements:
			reqs += req + ','
		gameTTS += reqs
	speakQueue.append(gameTTS)

func set_game_texts(label, words):
	label.set_word(words[0])
	label.set_label(words[1])

func tts_speak(text):
	$tts.speak(text)

func _process(delta):
	update_debug()
	update_state()
	update_tts()

func update_debug():
	if promptTypePool.size() > 0:
		if Input.is_action_just_pressed("new_prompt"):
			request_prompt(promptTypePool[rand_range(0, promptTypePool.size())])
			give_prompt()

	if Input.is_action_just_pressed("new_game"):
		# get_rand_game()
		$ClockPanel.zero_timer()
	
func update_state():
	match currentState:
		GAMESTATE.PRE_SHOW:	
			pass
		GAMESTATE.PRE_GAME:
			pass
		GAMESTATE.IN_GAME:
			pass
		GAMESTATE.POST_GAME:
			pass
		GAMESTATE.POST_SHOW:
			if not $tts._get_is_speaking():
				tts_speak("Show Over, Go Home.")
			
func set_state(newState):
	# on exit
	match currentState:
		GAMESTATE.PRE_SHOW:			
			pass
		GAMESTATE.PRE_GAME:
			pass
		GAMESTATE.IN_GAME:
			pass
		GAMESTATE.POST_GAME:
			pass
	currentState = newState
	# on enter
	match currentState:
		GAMESTATE.PRE_SHOW:
			speakQueue.append("The show will start in 5. 4.... 3. 2.... 1.")
			set_game_texts($ShowPanel, ["", ""])
			set_game_texts($ShowPanel2, ["", ""])
			$ClockPanel.set_manual_timer(7.0)
			pass
		GAMESTATE.PRE_GAME:
			get_rand_game()
			request_prompt(promptTypePool[rand_range(0, promptTypePool.size())])			
			set_game_texts($ShowPanel2, ["", ""])
			$ClockPanel.set_manual_timer(10.0)
			pass
		GAMESTATE.IN_GAME:
			reset_clock()
			emit_signal("clock_start")
			give_prompt()			
			pass
		GAMESTATE.POST_GAME:
			speakQueue.append("SCEEENE!... That was really funny ha, ha, ha, ha, ha.")	
			set_game_texts($ShowPanel, ["SCENE", ""])
			set_game_texts($ShowPanel2, ["SCENE", ""])
			$ClockPanel.set_manual_timer(10.0)			
			pass

func _on_ClockPanel_timer_reset():
	match currentState:
		GAMESTATE.PRE_SHOW:
			set_state(GAMESTATE.PRE_GAME)	
			pass
		GAMESTATE.PRE_GAME:
			set_state(GAMESTATE.IN_GAME)
			pass
		GAMESTATE.IN_GAME:
			set_state(GAMESTATE.POST_GAME)
			pass
		GAMESTATE.POST_GAME:
			set_state(GAMESTATE.PRE_GAME)
			pass

func full_request():
	request_prompt(promptTypePool[rand_range(0, promptTypePool.size())])
	get_rand_game()	

func reset_clock():
	$ClockPanel.set_new_timer(currentGame)

func request_prompt(type):
	promptEnum = type
	promptType = str(PROMPT_TYPE.keys()[type]).to_lower()
	set_game_texts($ShowPanel2, ["thinking...", ""])
	if net_mode:
		var result = $HTTPRequest.request("https://improbot.com/?key=" + promptType + "&n=" + str(prompt_pool_size) + "&lang=en")
	else:
		offline_prompt_request()

func update_tts():
	if not $tts._get_is_speaking() and speakQueue.size() > 0:
		var toSpeak = speakQueue[0]
		tts_speak(toSpeak)
		speakQueue.remove(0)
	
func _on_debug_prompt_pressed(prompt):
	var index = promptTypePool.find(prompt)
	if index == -1:
		promptTypePool.append(prompt)
	else:
		promptTypePool.remove(index)

func _on_ClockPanel_timer_ending():
	speakQueue.append("You have ten seconds left.")
	
func _on_ClockPanel_show_over():
	$ShowPanel.set_word("Show")
	$ShowPanel.set_label("")
	$ShowPanel2.set_word("Over")
	$ShowPanel2.set_label("")
	set_state(GAMESTATE.POST_SHOW)
