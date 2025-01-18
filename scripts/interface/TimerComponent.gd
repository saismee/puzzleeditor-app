extends Node

var value: int = 1

var icons: Dictionary = {
	inf = ContentLoader._load("res://themes/perpetual/assets/lcd/lcdnoreset.png"),
	clock = ContentLoader._load("res://themes/perpetual/assets/lcd/lcdtimer.png"),
	dash = ContentLoader._load("res://themes/perpetual/assets/lcd/lcd_null.png")
}
var timer_icons: Array = [
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0000.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0001.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0002.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0003.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0004.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0005.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0006.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0007.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0008.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0009.png")
]

@onready var digits: Array = [
	get_node("Digit0"),
	get_node("Digit1"),
	get_node("Digit2"),
	get_node("Digit3")
]

@onready var end: TextureRect = get_node("End")

func set_value(new: int) -> void:
	if !is_node_ready():
		await ready
	value = new
	
	var string: String = str(value)
	string = string.substr(max(string.length()-4, 0))
	if string.length() < 2:
		string = "0" + string
	
	for i in 4:
		digits[i].visible = (i < string.length()) or (i < 2)
		if !digits[i].visible:
			continue
		if value == 0:
			digits[i].texture = icons.dash
		else:
			digits[i].texture = timer_icons[int(string.substr(i, 1))]
	
	end.texture =  icons.inf if value == 0 else icons.clock
