class_name CESwitchNode
extends CEBaseNode

var case_count = 0

func _init2() -> void:
	var add_switch: Button = Button.new()
	add_switch.text = "+"
	add_switch.pressed.connect(add_case)
	get_titlebar_hbox().add_child(add_switch)

func add_case(index = "") -> void:
	add_string_control("results", index, str(case_count))
	set_slot_enabled_left(2 + case_count, true)
	case_count += 1
