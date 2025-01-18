extends PopupMenu

@onready var Entities = get_node("../Entities")

func _update():
	for entity in Entities.valid_entities:
		add_item(entity.name)
