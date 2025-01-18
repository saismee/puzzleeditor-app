extends Window


func _process(delta):
	position.x = clamp(position.x, 10, get_tree().root.get_viewport().size.x - 10 - get_viewport().size.x)
	position.y = clamp(position.y, 40, get_tree().root.get_viewport().size.y - 10 - get_viewport().size.y)
