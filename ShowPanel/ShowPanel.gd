tool
extends TextureRect

export var bbcode = "[center]"
export var PanelLabel = "Game"
export var PanelContent = "Toaster"


# Called when the node enters the scene tree for the first time.
func _ready():
	$PanelLabel.bbcode_text = bbcode + PanelLabel
	$PanelWord.bbcode_text = bbcode + PanelContent

func _process(delta):
	if Engine.editor_hint:
		$PanelLabel.bbcode_text = bbcode + PanelLabel
		$PanelWord.bbcode_text = bbcode + PanelContent

func set_word(newWord):
	PanelContent = newWord
	$PanelWord.bbcode_text = bbcode + PanelContent
	
func set_label(label):
	PanelLabel = label
	$PanelLabel.bbcode_text = bbcode + PanelLabel
