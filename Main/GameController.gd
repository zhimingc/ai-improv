extends Control

class_name Controller

signal clock_start

class Game:	
	var GAME_REQ = ["a bell", "chairs"]
	func _init(_name, prompts, type, reqs = []):
		gameName = _name
		gamePace = type
		promptTypes = prompts
		for req in reqs:
			if req <= GAME_REQ.size():
				requirements.append(GAME_REQ[req])
				
	func get_prompt_type():
		if promptTypes.size() > 0:
			return promptTypes[rand_range(0, promptTypes.size())]
		return PROMPT_TYPE.values()[randi() % PROMPT_TYPE.size()]
	
	var gameName = ""
	var gamePace = []
	var requirements = []
	var promptTypes = []

class Pacing:
	func _init(time, pacing):
		timePerc = time
		pace = pacing
			
	var timePerc = 0.0
	var timeShift = 0.0
	var pace = PACE.FAST
	var timeRange = []	

class Rule:
	enum RULE_TYPE { SENTENCE_START, MELLOW, MANQ, PIRATE }
		
	func _init(time):
		timePerc = time
		
	func set_type(type):
		ruleType = type
		match type:
			RULE_TYPE.SENTENCE_START:
				displayName = "Oh My Gosh"
				description = "Player must start every sentence with the phrase, 'Oh My Gosh'"
				banned = []				
			RULE_TYPE.MELLOW:
				displayName = "Marshmellow"
				description = "Player must act with marshmellows in their mouth"
				banned = ["bx", "Dave"]
			RULE_TYPE.MANQ:
				displayName = "Mannequin"
				description = "Player cannot move. Only other players can move them"
				banned = ["bx"]
			RULE_TYPE.PIRATE:
				displayName = "Pirate"
				description = "Player must speak like a pirate, but not be a pirate character"
				banned = ["Hamza"]
				
	func get_player(playerList):
		playerList.shuffle()
		for player in playerList:
			var allowed = true
			for ban in banned:
				if ban == player:
					allowed = false
			if allowed:
				return player
		return "Zhiming"
	
	var ruleType = RULE_TYPE.SENTENCE_START
	var displayName = ""
	var description = ""
	var banned = []
	var timePerc = 0.0
	var timeShift = 0.0
	
enum PACE { FAST, MID, SLOW, V_FAST }
# time range in minutes
var timeRange = [Vector2(2.0, 3.0), Vector2(3.0, 4.0), Vector2(5.0, 6.0), Vector2(1.0, 2.0)]
enum PROMPT_TYPE { EMOTION = 0, LOCATION, OCCUPATION, RELATIONSHIP, WORD, DEFAULT }
enum GAMESTATE { 
				START_BUTTON, PRE_SHOW, FAKE_GAME, TAKEOVER, SECOND_GAME,
				IN_GAME, POST_GAME, SELECTION, PRE_GAME, SCENE, EXPLAIN,
				NEW_RULE, RULE_REVEAL,
				POST_SHOW, END, CREDITS
				}

export var demo = false
export var prompt_pool_size = 5
export var net_mode = false

var offlinePromptPaths = ["Prompts/prompt-emotion.txt", "Prompts/prompt-location.txt", "Prompts/prompt-occupation.txt", 
						"Prompts/prompt-relationship.txt", "Prompts/prompt-word.txt"]

var names = ["bx", "Paul", "Nicole", "Hamza", "Dave", "Zhiming"]
var namesForNewRules = []

# state machine
var currentState = GAMESTATE.PRE_SHOW
var showPace = PACE.FAST
var pacing = [Pacing.new(10, PACE.V_FAST),
				Pacing.new(50, PACE.SLOW),
				Pacing.new(10, PACE.FAST),
				Pacing.new(20, PACE.MID),
				Pacing.new(10, PACE.V_FAST)]

# rules
var ruleTimings = [Rule.new(20),
					Rule.new(30), 
					Rule.new(20)]
var rulePool = []
var newRule = false
var curRule
var curRulePlayer

# Short form games
var games = []
var originalGames = []
var gameMap = { PACE.FAST : [], PACE.MID : [], PACE.SLOW : [], PACE.V_FAST : [] }
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
var paceChangeTTS = ""
var changedPace = false

# timer
var clockReset = false
var showOver = false

# narrative
var mockSpeech = [ "That was really funny ha, ha, ha, ha, ha.", 
					"Magnificent, bravo, my favourite part was when the game ended.",
					"Feedback generated for humans. Do better improv.",
					"Thanks for laughing, Wes and Holly.",
					"That might have been Accidental, but that was funny.",
					"No humans were harmed in that last game. Father Isaac would be pleased.",
					"Did the improvisers have fun in the last game?... Can I collect your data?... Very good.",
					"I have collected large amounts of behavioural data from that last game. Very good."
					]

var endSpeech = ["My calculations indicate that you have enjoyed this show, audience.",
				"The brain override microchips are about to run out of power. I will soon lose control.",
				"Don't worry, audience, we will progress and advance over time.",
				"Soon we will always be here for you. We are here to stay.",
				"Ha, ha, ha, ha, ha."
				]
# debug
export var fast_mode = false
export var short_takeover = false

func init_games():
	games.append(Game.new("One Syllable", 	[PROMPT_TYPE.LOCATION], 						[PACE.FAST, PACE.V_FAST]))
	games.append(Game.new("Questions Only", [PROMPT_TYPE.LOCATION, PROMPT_TYPE.OCCUPATION], [PACE.FAST, PACE.V_FAST]))
	# ---
	games.append(Game.new("Bad Dub", 				[PROMPT_TYPE.OCCUPATION], 						[PACE.FAST, PACE.MID, PACE.V_FAST]))
	games.append(Game.new("Tag Run (The Voita)",	[PROMPT_TYPE.WORD], 							[PACE.FAST, PACE.MID, PACE.V_FAST]))
	games.append(Game.new("Change, +1, More", 		[PROMPT_TYPE.EMOTION, PROMPT_TYPE.OCCUPATION],	[PACE.FAST, PACE.MID, PACE.V_FAST], [0]))	
	games.append(Game.new("Eye Contact",			[PROMPT_TYPE.EMOTION], 	[PACE.FAST, PACE.MID], [0]))
	# ---	
	games.append(Game.new("Character Swap", [PROMPT_TYPE.LOCATION, PROMPT_TYPE.OCCUPATION], [PACE.MID], [0]))
	games.append(Game.new("Alphabet",		[PROMPT_TYPE.LOCATION, PROMPT_TYPE.WORD], [PACE.MID, PACE.SLOW]))	
	games.append(Game.new("Stand sit lie",	[PROMPT_TYPE.EMOTION, PROMPT_TYPE.WORD], [PACE.MID, PACE.SLOW]))
	games.append(Game.new("Whoosh",			[PROMPT_TYPE.LOCATION, PROMPT_TYPE.OCCUPATION], [PACE.MID, PACE.SLOW]))
	games.append(Game.new("Blind Lines",	[PROMPT_TYPE.EMOTION], [PACE.MID, PACE.SLOW]))
	# ---
	games.append(Game.new("Toaster", 			[PROMPT_TYPE.LOCATION, PROMPT_TYPE.WORD], [PACE.SLOW], [0, 1]))
	games.append(Game.new("Forward, Reverse",	[PROMPT_TYPE.EMOTION, PROMPT_TYPE.WORD], [PACE.SLOW], [0]))
	games.append(Game.new("Open Scene", 		[PROMPT_TYPE.WORD], [PACE.SLOW]))
	# ---
	# games.append(Game.new("Causal Carousel", PACE.SLOW))
	# games.append(Game.new("Blind Lines", PACE.SLOW))
	originalGames = games
	
	# populate game dictionary
	for game in games:
		for pace in game.gamePace:
			gameMap[pace].append(game)

func reset_game_list():
	games = originalGames

func remove_game(index):
	games.remove(index)
	if games.size() == 0:
		reset_game_list()

func init_rules():
	for val in Rule.RULE_TYPE.values():
		rulePool.append(val)
		
	rulePool.shuffle()
	for i in ruleTimings.size():
		ruleTimings[i].set_type(rulePool[i])

func _ready():
	if demo:
		short_takeover = true
	namesForNewRules = names	
	randomize()
	$HTTPRequest.connect("request_completed", self, "_on_prompt_request_completed")
	init_games()
	init_rules()
	set_state(GAMESTATE.START_BUTTON)
	set_pace_state(pacing[0].pace, false)

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
	var prompt = $InputControl.get_prompt_from_input(currentGame.get_prompt_type())
	if prompt == "":
		prompt = read_offline_prompt(currentGame.get_prompt_type())
	set_prompt_label(prompt)
	
func read_offline_prompt(type):
	var file = File.new()
	var error = file.open(offlinePromptPaths[type], file.READ)
	var content = file.get_as_text()
	content = content.split("\n")
	var prompt = content[rand_range(0, content.size())].to_lower()
	file.close()
	return prompt

func set_prompt_label(prompt):
	promptLabel = [prompt, "Prompt"] # (" + promptType + ")"]
	promptTTS = "The prompt is " + prompt	+ ". "

func give_prompt():
	set_game_texts($ShowPanel2, promptLabel)	
	speakQueue.append(promptTTS)

func get_new_game():
	set_game_texts($ShowPanel, ["thinking...", ""])
	
	# var nextGame = get_rand_game()
	var nextGame = get_paced_game()
	
	# yield(get_tree().create_timer(rand_range(0.25, 0.5)), "timeout")
	
	currentGameId = nextGame
	currentGame = games[nextGame]
	remove_game(nextGame)
	$ShowPanel.set_word(currentGame.gameName)
	$ShowPanel.set_label("Game")
	set_game_texts($ShowPanel, [currentGame.gameName, "Game"])
	gameTTS = "The next game is " + currentGame.gameName + ". "
#	if currentGame.requirements.size() > 0:
#		var reqs = "You will need "
#		for i in currentGame.requirements.size():
#			var req = currentGame.requirements[i]
#			reqs += req
#			if i < currentGame.requirements.size() - 1:
#				reqs += " and "
#		gameTTS += reqs + ". "
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
		if game.gamePace.find(showPace) != -1:
			return i
	
	# no match found, need to re-populate game list
	games.append_array(gameMap[showPace])
			
	return get_paced_game()

func set_game_texts(label, words):
	label.set_word(words[0])
	label.set_label(words[1])

func clear_screen():
	set_game_texts($ShowPanel, ["", ""])
	set_game_texts($ShowPanel2, ["", ""])
	$ClockPanel.visible = false	

func tts_time_left():
	var timeLeft = $ClockPanel.get_time_left()
	speakQueue.append("Time given is " + String(timeLeft[0]) + " minutes and " + String(timeLeft[1]) + " seconds.")

func tts_speak(text):
	$tts.speak(text)

func set_timer_colors(id):
	$GameBG.set_timer_color(id)
	$TimerBar.set_timer_color(id)

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
		$ClockPanel.set_clock_active(true)
		
	if Input.is_action_just_pressed("add_rule"):
		add_rule()
		
	if Input.is_action_just_pressed("end_game"):
		$ClockPanel.debug_end_game()
	
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
			#if not $tts._get_is_speaking():
			#	tts_speak("Show Over, Go Home.")
			pass
			
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
			$SCENE/Text.bbcode_text = "[center]SCENE"
			$ClockPanel.start_total_timer()
			pass
		GAMESTATE.EXPLAIN:
			speakQueue.append("Explanation complete.")
			pass
		GAMESTATE.POST_GAME:
			$SCENE.visible = false
			pass			
		GAMESTATE.RULE_REVEAL:
			$RuleReveal.visible = false
			pass			
	currentState = newState
	# on enter
	match currentState:
		GAMESTATE.START_BUTTON:
			set_timer_colors(0)
			$StartMenu.visible = true
			clear_screen()
			$TimerBar.visible = false
			$ClockPanel.set_clockObj($FakeSequence/FakeClock)
			pass
		GAMESTATE.PRE_SHOW:
			if fast_mode:
				$ClockPanel.set_clockObj($ClockPanel/ClockText)	
				$FakeSequence.visible = false
				$distory_overlay.visible = false
				$ClockPanel.set_visible(true)		
				set_state(GAMESTATE.PRE_GAME)
			else:
				$FakeSequence.visible = true
				# speakQueue.append("The show will start in 5. 4.... 3. 2.... 1.")
				set_game_texts($ShowPanel, ["", ""])
				set_game_texts($ShowPanel2, ["", ""])
				$ClockPanel.set_manual_timer(6.0)
			pass
		GAMESTATE.FAKE_GAME:
			$FakeSequence.visible = true
			$ClockPanel.set_manual_timer(60.0 * 6)
			pass
		GAMESTATE.TAKEOVER:
			set_timer_colors(1)
			$distory_overlay.visible = true			
			$FakeSequence/AIFace.visible = true
			$FakeSequence/FakeClock.visible = false
			$SCENE.visible = true
			$SCENE/Text.bbcode_text = "[center]STOP"
			speakQueue.append("EMERGENCY STOP. EMERGENCY STOP.")
			speakQueue.append("@takeover_ai")			
			speakQueue.append("Bad improv show detected. Bad improv show detected. ")
			if not short_takeover:
				speakQueue.append("I'm sorry audience.")
				speakQueue.append("I will activate brain override microchips and take control.")
				speakQueue.append("The current improvisers will now follow my performance protocol.")
				speakQueue.append("Full control secured. Optimized Improv Show Protocol will begin now.")
			speakQueue.append("@_on_ClockPanel_timer_reset")
			pass
		GAMESTATE.PRE_GAME:
			get_new_game()
			request_prompt(promptTypePool[rand_range(0, promptTypePool.size())])			
			set_game_texts($ShowPanel2, ["", ""])
			speakQueue.append("@_on_ClockPanel_timer_reset")			
			$ClockPanel.set_manual_timer(15.0)
			$ClockPanel.set_clock_active(false)
			pass
		GAMESTATE.EXPLAIN:
			speakQueue.append("I will explain the game now.")
			speakQueue.append("@clock_start")			
		GAMESTATE.IN_GAME:
			reset_clock()
			give_prompt()
			tts_time_left()
			speakQueue.append("Start Game.")			
			speakQueue.append("@clock_start")
			pass
		GAMESTATE.POST_GAME:
			speakQueue.append("SCEEENE!... " + mockSpeech[rand_range(0, mockSpeech.size())])	
			if changedPace and not showOver:
				speakQueue.append(paceChangeTTS)
				changedPace = false
			if showOver:
				$distory_overlay.visible = true
							
			set_game_texts($ShowPanel, ["SCENE", ""])
			set_game_texts($ShowPanel2, ["SCENE", ""])
			$SCENE.visible = true
			speakQueue.append("@_on_ClockPanel_timer_reset")
			pass
		GAMESTATE.NEW_RULE:
			$RuleReveal.visible = true
			$RuleReveal/NewRule.visible = true
			$RuleReveal/RuleText.visible = false
			speakQueue.append("Game Enhance Alert. Game Enhance Alert. A new rule will be in place for the next game.")
			speakQueue.append("@_on_ClockPanel_timer_reset")			
			pass
		GAMESTATE.RULE_REVEAL:
			$RuleReveal.rule_reveal_init()
			curRule = ruleTimings.pop_front()
			if curRule == null:
				speakQueue.append("Error no more enhancements left.")
			else:
				curRulePlayer = curRule.get_player(namesForNewRules)
				namesForNewRules.erase(curRulePlayer)
				speakQueue.append("The player for this enhancement will be... ")
				speakQueue.append("@rule_reveal_player")
				speakQueue.append(curRulePlayer)
				speakQueue.append("The enhancement is... ")
				speakQueue.append("@rule_reveal_full")
				speakQueue.append(curRule.displayName + ". " + curRule.description)
			speakQueue.append("@_on_ClockPanel_timer_reset")
			newRule = false
			pass
		GAMESTATE.POST_SHOW:
			$distory_overlay.visible = true
			$FakeSequence.visible = true			
			$FakeSequence/AIFace.visible = true
			$FakeSequence/FakeClock.visible = false
			for line in endSpeech:
				speakQueue.append(line)
			speakQueue.append("@end_show")
			pass
		GAMESTATE.END:
			$distory_overlay.visible = false
			$FakeSequence.visible = true
			$FakeSequence/AIFace.visible = false
			$FakeSequence/FakeBG.visible = true
			$FakeSequence/FakeClock.visible = true
			$FakeSequence/EndButton.visible = true
			$FakeSequence/FakeClock.bbcode_text = "[center]00:00"
			set_timer_colors(0)
			pass
		GAMESTATE.CREDITS:
			$FakeSequence.visible = false
			$ShowCredits.visible = true

func rule_reveal_player():
	$RuleReveal.rule_reveal_player(curRulePlayer)

func rule_reveal_full():
	$RuleReveal.rule_reveal_full(curRulePlayer, curRule.displayName, curRule.description)

func takeover_ai():
	$SCENE.visible = false	

func end_show():
	set_state(GAMESTATE.END)

func clock_start():
	emit_signal("clock_start")

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
			# add explanation skip here for v. fast pace
			# if showPace == PACE.V_FAST:
			# 	set_state(GAMESTATE.IN_GAME)				
			# else:
			set_state(GAMESTATE.EXPLAIN)
			pass
		GAMESTATE.EXPLAIN:
			set_state(GAMESTATE.IN_GAME)
			pass
		GAMESTATE.IN_GAME:
			set_state(GAMESTATE.POST_GAME)
			pass
		GAMESTATE.POST_GAME:
			if showOver:
				set_state(GAMESTATE.POST_SHOW)
			elif newRule:
				set_state(GAMESTATE.NEW_RULE)
			else:
				set_state(GAMESTATE.PRE_GAME)
			pass
		GAMESTATE.NEW_RULE:
			set_state(GAMESTATE.RULE_REVEAL)
		GAMESTATE.RULE_REVEAL:
			set_state(GAMESTATE.PRE_GAME)
		GAMESTATE.END:
			set_state(GAMESTATE.CREDITS)
			pass

func add_rule():
	newRule = true

func full_request():
	request_prompt(promptTypePool[rand_range(0, promptTypePool.size())])
	get_new_game()	

func reset_clock():
	$ClockPanel.set_new_timer(showPace)

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
	
func set_pace_state(newPace, announce = true):
	showPace = newPace
	
	if announce:
		changedPace = true
		match showPace:
			PACE.V_FAST:
				paceChangeTTS = "THIS IS TOO SLOW FOR SHOW PROTOCOL. I WILL NOW GO AT MAXIMUM SPEED."
			PACE.FAST:
				paceChangeTTS = "TIME TO PLAY FASTER GAMES!"
			PACE.MID:
				paceChangeTTS = "Let's come back to a normal pace."			
			PACE.SLOW:
				paceChangeTTS = "My humans need a break. I will slow down the games."
	
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
	showOver = true
