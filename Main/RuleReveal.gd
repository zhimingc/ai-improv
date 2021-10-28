extends TextureRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func rule_reveal_init():
	$RuleText.bbcode_text = "[center]player\n*\n"
	$NewRule.visible = false	
	$RuleText.visible = true

func rule_reveal_full(player, rule_name, description):
	$RuleText.bbcode_text = "[center]player\n*\n" + player + "\n\n" + rule_name + "\n*\n" + description
	
func rule_reveal_player(player):
	$RuleText.bbcode_text = "[center]player\n*\n" + player
