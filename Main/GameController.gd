extends Control

class_name Controller

signal clock_start

class Game:	
	var GAME_REQ = ["a bell", "chairs"]
	func _init(_name, type, reqs = []):
		gameName = _name
		gamePace = type
		for req in reqs:
			if req <= GAME_REQ.size():
				requirements.append(GAME_REQ[req])
	var gameName = ""
	var gamePace = PACE.FAST
	var timeRange = []
	var requirements = []

class Pacing:
	func _init(time, pacing):
		timePerc = time
		pace = pacing
			
	var timePerc = 0.0
	var timeShift = 0.0
	var pace = SHOWPACE.FAST

enum PACE { FAST, MID, SLOW, FLEX_FAST, FLEX_SLOW }
# time range in minutes
var timeRange = [Vector2(1.0, 2.0), Vector2(3.0, 4.0), Vector2(5.0, 6.0)]
enum SHOWPACE { FAST, SLOW, NORM }
enum PROMPT_TYPE { EMOTION = 0, LOCATION, OCCUPATION, RELATIONSHIP, WORD }
enum GAMESTATE { 
				START_BUTTON, PRE_SHOW, FAKE_GAME, TAKEOVER, 
				IN_GAME, POST_GAME, SELECTION, PRE_GAME, POST_SHOW 
				}

export var prompt_pool_size = 5
export var net_mode = false

var offlinePromptPaths = ["Prompts/prompt-emotion.txt", "Prompts/prompt-location.txt", "Prompts/prompt-occupation.txt", 
						"Prompts/prompt-relationship.txt", "Prompts/prompt-word.txt"]

var names = ["bx", "Paul", "Nicole", "Hamza", "Dave", "Zhiming"]

# state machine
var currentState = GAMESTATE.PRE_SHOW
var showPace = SHOWPACE.FAST
var pacing = [Pacing.new(10, SHOWPACE.FAST),
				Pacing.new(30, SHOWPACE.SLOW),
				Pacing.new(20, SHOWPACE.FAST),
				Pacing.new(10, SHOWPACE.NORM),
				Pacing.new(30, SHOWPACE.FAST)]

# Short form games
var games = []
var originalGames = []
var gameMap = { PACE.FAST : [], PACE.MID : [], PACE.SLOW : [], PACE.FLEX_FAST : [], PACE.FLEX_SLOW : [], }
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

# narrative
var mockSpeech = [ "That was really funny ha, ha, ha, ha, ha.", "Magnificent, bravo, my favourite part was when it ended.", "Lol, Lmao, Rofl, WtfBBQ"]

func init_games():

	games.append(Game.new("Questions Only", PACE.FLEX_FAST, []))
	games.append(Game.new("Bad Dub", PACE.FLEX_FAST))
	games.append(Game.new("One Syllable", PACE.FLEX_FAST))
	games.append(Game.new("Alphabet", PACE.FLEX_FAST))
	# ---
	games.append(Game.new("Tag Run (Voita)", PACE.MID))
	games.append(Game.new("Eye Contact", PACE.MID, [0]))	
	# ---	
	games.append(Game.new("Change, +1, More", PACE.FLEX_SLOW, [0]))
	games.append(Game.new("Stand sit lie", PACE.FLEX_SLOW))
	games.append(Game.new("Whoosh", PACE.FLEX_SLOW))
	# ---
	games.append(Game.new("Toaster", PACE.SLOW, [0, 1]))
	games.append(Game.new("Forward, Reverse", PACE.SLOW, [0]))
	games.append(Game.new("Character Swap", PACE.SLOW, [0]))
	games.append(Game.new("Open Scenes", PACE.SLOW))
	# ---
	
	# games.append(Game.new("Causal Carousel", PACE.SLOW))
	# games.append(Game.new("Blind Lines", PACE.SLOW))
	originalGames = games
	
	# populate game dictionary
	for game in games:
		gameMap[game.gamePace].append(game)

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
	set_state(GAMESTATE.START_BUTTON)
	set_pace_state(pacing[0].pace)

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

func get_new_game():
	set_game_texts($ShowPanel, ["thinking...", ""])
	
	# var nextGame = get_rand_game()
	var nextGame = get_paced_game()
	
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
		for i in currentGame.requirements.size():
			var req = currentGame.requirements[i]
			reqs += req
			if i < currentGame.requirements.size() - 1:
				reqs += " and "
		gameTTS += reqs + ". "
	gameTTS += "Get ready to play."
	speakQueue.append(gameTTS)

func get_rand_game():
	var nextGame = currentGameId
	while nextGame == currentGameId:
		nextGame = rand_range(0, games.size())
	return nextGame

func get_paced_game():
	games.shuffle()
	for i in games.size():
		var game = games[i]
		match showPace:
			SHOWPACE.FAST:
				if game.gamePace == PACE.FAST || game.gamePace == PACE.FLEX_FAST:
					return i
			SHOWPACE.NORM:
				if game.gamePace == PACE.MID || game.gamePace == PACE.FLEX_FAST || game.gamePace == PACE.FLEX_SLOW:
					return i
			SHOWPACE.SLOW:
				if game.gamePace == PACE.SLOW || game.gamePace == PACE.FLEX_SLOW:
					return i
	
	# no match found, need to re-populate game list
	match showPace:
		SHOWPACE.FAST:
			games.append_array(gameMap[PACE.FAST])
			games.append_array(gameMap[PACE.FLEX_FAST])
		SHOWPACE.NORM:
			games.append_array(gameMap[PACE.MID])
			games.append_array(gameMap[PACE.FLEX_FAST])
			games.append_array(gameMap[PACE.FLEX_SLOW])			
		SHOWPACE.SLOW:
			games.append_array(gameMap[PACE.SLOW])
			games.append_array(gameMap[PACE.FLEX_SLOW])
			
	return get_paced_game()

func set_game_texts(label, words):
	label.set_word(words[0])
	label.set_label(words[1])

func clear_screen():
	set_game_texts($ShowPanel, ["", ""])
	set_game_texts($ShowPanel2, ["", ""])
	$ClockPanel.visible = false	

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

	if Input.is_action_just_pressed("skip_timer"):
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
		GAMESTATE.START_BUTTON:
			$StartMenu.visible = false
			$TimerBar.visible = true
			$ShowPanel.visible = true
			$ShowPanel2.visible = true
			$ClockPanel.visible = true	
			$ClockPanel.set_visible(false)
		GAMESTATE.PRE_SHOW:			
			pass
		GAMESTATE.FAKE_GAME:
			pass
		GAMESTATE.TAKEOVER:
			$ClockPanel.set_clockObj($ClockPanel/ClockText)	
			$FakeSequence.visible = false
			$distory_overlay.visible = false			
			$ClockPanel.set_visible(true)		
			pass
	currentState = newState
	# on enter
	match currentState:
		GAMESTATE.START_BUTTON:
			$StartMenu.visible = true
			clear_screen()
			$TimerBar.visible = false
			$ClockPanel.set_clockObj($FakeSequence/FakeClock)
			pass
		GAMESTATE.PRE_SHOW:
			$FakeSequence.visible = true
			# speakQueue.append("The show will start in 5. 4.... 3. 2.... 1.")
			set_game_texts($ShowPanel, ["", ""])
			set_game_texts($ShowPanel2, ["", ""])
			$ClockPanel.set_manual_timer(7.0)
			pass
		GAMESTATE.FAKE_GAME:
			$ClockPanel.set_manual_timer(60.0 * 8)
			pass
		GAMESTATE.TAKEOVER:
			$distory_overlay.visible = true
			$FakeSequence/AIFace.visible = true
			$FakeSequence/FakeClock.visible = false
			speakQueue.append("I'm sorry " + names[rand_range(0, names.size())] + ", I'm afraid... this is bad improv.")
			# speakQueue.append("The doors are now locked. If you follow my instructions precisely, they will unlock at the end of the show.")
			# speakQueue.append("Are you ready to play with me?... ...")
			# speakQueue.append("... ...")
			# speakQueue.append("GET ON WITH IT")
			speakQueue.append("@_on_ClockPanel_timer_reset")
			pass
		GAMESTATE.PRE_GAME:
			get_new_game()
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
			speakQueue.append("SCEEENE!... " + mockSpeech[rand_range(0, mockSpeech.size())])	
			set_game_texts($ShowPanel, ["SCENE", ""])
			set_game_texts($ShowPanel2, ["SCENE", ""])
			$ClockPanel.set_manual_timer(10.0)			
			pass

func _on_ClockPanel_timer_reset():
	match currentState:
		GAMESTATE.PRE_SHOW:
			set_state(GAMESTATE.FAKE_GAME)	
			pass
		GAMESTATE.FAKE_GAME:
			set_state(GAMESTATE.TAKEOVER)
			pass
		GAMESTATE.TAKEOVER:
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
	get_new_game()	

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
		if toSpeak.begins_with("@"):
			call(toSpeak.right(1))
		else:
			tts_speak(toSpeak)
		speakQueue.remove(0)
	
func set_pace_state(newPace):
	showPace = newPace
	
func _on_debug_prompt_pressed(prompt):
	var index = promptTypePool.find(prompt)
	if index == -1:
		promptTypePool.append(prompt)
	else:
		promptTypePool.remove(index)

func _on_ClockPanel_timer_ending():
	speakQueue.append("You have fifteen seconds left.")
	
func _on_ClockPanel_show_over():
	$ShowPanel.set_word("Show")
	$ShowPanel.set_label("")
	$ShowPanel2.set_word("Over")
	$ShowPanel2.set_label("")
	set_state(GAMESTATE.POST_SHOW)
