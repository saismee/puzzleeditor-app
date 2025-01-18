extends Node

@onready var output = get_tree().get_root().get_node("Spatial/UI/Inner/Output")

var log = PackedStringArray()
var max_lines = 50

var log_verbose = false
const error_popups = true

func _log(text):
	log.append(text)
	if output:
		output.set_text("\n".join(log))
		#.slice(log.size() - max_lines)

func set_console_visible(visible: bool):
	output.set_visible(visible)

func info(text):
	_log("[color=lightgray]" + str(text) + "[/color]")
	print(text)

func verbose(text):
	if log_verbose:
		_log("[color=deepskyblue]ℹ " + str(text) + "[/color]")
		print(text)

func warn(text):
	_log("[color=yellow]⚠ " + str(text) + "[/color]")
	push_warning(text)
	
func error(text):
	_log("[color=red]❌ " + str(text) + "[/color]")
	if error_popups:
		SPopup.new("Error!", "PuzEdit encountered an error!\n" + text)
	push_error(text)

func check(value, text):
	if !value or value == null:
		error(text)
