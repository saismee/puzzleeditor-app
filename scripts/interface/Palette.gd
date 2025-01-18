extends Control

@onready var palette_container: GridContainer = get_node("Panel/ScrollContainer/GridContainer")
@onready var palette_entry: PackedScene = ContentLoader._load("res://scenes/palette_entry.tscn")
@onready var panel: Panel = get_node("Panel")

var menu_tween: Tween

func _ready() -> void:
	update_palette()
	
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)

func _mouse_entered() -> void:
	if menu_tween: menu_tween.kill()
	menu_tween = create_tween()
	menu_tween.tween_property(panel, "position", Vector2(0, 0), 0.1)

func _mouse_exited() -> void:
	if menu_tween: menu_tween.kill()
	menu_tween = create_tween()
	menu_tween.tween_property(panel, "position", Vector2(-550, 0), 0.1)

func update_palette() -> void:
	if !palette_container: return
	
	for node: Node in palette_container.get_children():
		palette_container.remove_child(node)
		node.queue_free()
	
	for entity: String in Data.registered_entities:
		if Util.has(Data.registered_entities[entity].editor, "hidden", false) and (not Util.has(Data.global_config.options, "developer_mode", false)): continue
		var new_entry: Button = palette_entry.instantiate()
		new_entry.get_node("Image").texture = Util.has(Data.registered_entities[entity], "icon", ContentLoader._load("res://themes/perpetual/assets/empty.png"))
		new_entry.name = entity
		new_entry.entity_name = entity
		
		palette_container.add_child(new_entry)
