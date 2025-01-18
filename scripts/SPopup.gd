extends Node

@onready var UI = get_tree().root.get_node("Spatial/UI")

func new(title: String, text: String, button_text: String = "OK") -> AcceptDialog:
	var popup = AcceptDialog.new()
	popup.title = title
	popup.size = Vector2i(400, 200)
	popup.position = Vector2i(get_viewport().size.x / 2 - 200, get_viewport().size.y / 2 - 100)
	popup.ok_button_text = button_text
	
	popup.transient = false
	
	popup.dialog_text = text
	
#	var label = Label.new()
#	label.text = text
#	label.add_theme_color_override("font_color", Color(200, 200, 0))
#
#	popup.add_child(label)
	
	popup.theme = ContentLoader._load("res://themes/perpetual/perpetual_dialog.tres")
	
	popup.visible = true
	
	UI.add_child(popup)
	
	return popup
