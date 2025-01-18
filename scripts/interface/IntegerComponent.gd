extends Node

var value: int = 1

var icons: Dictionary = {
	inf = ContentLoader._load("res://themes/perpetual/assets/lcd/lcdnoreset.png"),
	clock = ContentLoader._load("res://themes/perpetual/assets/lcd/lcdtimer.png"),
	blank = ContentLoader._load("res://themes/perpetual/assets/lcd/lcdend.png"),
	kg = ContentLoader._load("res://themes/perpetual/assets/lcd/lcdendkg.png"),
	theta = ContentLoader._load("res://themes/perpetual/assets/lcd/lcdendtheta.png"),
	newtons = ContentLoader._load("res://themes/perpetual/assets/lcd/lcdendnewtons.png"),
	dash = ContentLoader._load("res://themes/perpetual/assets/lcd/lcd_null.png")
}
var counter_icons: Array = [
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0000.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0001.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0002.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0003.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0004.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0005.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0006.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0007.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0008.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcd0009.png"),
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcdminus.png")
]

@onready var digits: Array = [
	get_node("Digit0"),
	get_node("Digit1"),
	get_node("Digit2"),
	get_node("Digit3")
]

@onready var end: TextureRect = get_node("End")

func set_icon(new: Variant) -> void:
	if !is_node_ready():
		await ready
	end.texture = icons[new] if icons.has(new) else new

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
		var str := string.substr(i, 1)
		if str == "-":
			digits[i].texture = counter_icons[10]
		else:
			digits[i].texture = counter_icons[int(str)]
