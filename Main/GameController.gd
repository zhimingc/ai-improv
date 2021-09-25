extends Control

enum PROMPT_TYPE { EMOTION, LOCATION, OCCUPATION, RELATIONSHIP }

export var prompt_pool_size = 5

var promptType
var promptTypePool = [0, 1, 2, 3]
var requesting = false

func _ready():
	$HTTPRequest.connect("request_completed", self, "_on_prompt_request_completed")

func _on_prompt_request_completed(result, response_code, headers, body):
	# var json = JSON.parse(body.get_string_from_utf8())
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
	requesting = false

func _process(delta):
	if Input.is_action_just_pressed("ui_select") and promptTypePool.size() > 0 and requesting == false:
		request_prompt(promptTypePool[rand_range(0, promptTypePool.size())])

func request_prompt(type):
	promptType = str(PROMPT_TYPE.keys()[type]).to_lower()
	var result = $HTTPRequest.request("https://improbot.com/?key=" + promptType + "&n=" + str(prompt_pool_size) + "&lang=en")
	$ShowPanel2.set_word("thinking...")
	$ShowPanel2.set_label("")
	requesting = true
	
func _on_debug_prompt_pressed(prompt):
	var index = promptTypePool.find(prompt)
	if index == -1:
		promptTypePool.append(prompt)
	else:
		promptTypePool.remove(index)
