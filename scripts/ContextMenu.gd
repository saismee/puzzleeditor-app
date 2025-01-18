extends PopupMenu

@onready var Entities = get_tree().root.get_node("Spatial/Entities")
@onready var Selection = get_tree().root.get_node("Spatial/Selection")
@onready var Connections = get_tree().root.get_node("Spatial/UI/Connections")
#@onready var shadow = get_node("../ContextShadow")

var current_options = {}
var current_entity = null
var current_voxel = null

var icons = {
	checked = ContentLoader._load("res://themes/perpetual/assets/check.png"),
	unchecked = ContentLoader._load("res://themes/perpetual/assets/uncheck.png"),
	partially_checked = ContentLoader._load("res://themes/perpetual/assets/check_partial.png"),
	cancel = ContentLoader._load("res://themes/perpetual/assets/cancel.png"),
	carve = ContentLoader._load("res://themes/perpetual/assets/carve.png"),
	radio = ContentLoader._load("res://themes/perpetual/assets/radio.png"),
	unradio = ContentLoader._load("res://themes/perpetual/assets/unradio.png"),
	empty = ContentLoader._load("res://themes/perpetual/assets/empty.png"),
	
	up = ContentLoader._load("res://themes/perpetual/assets/up.png"),
	down = ContentLoader._load("res://themes/perpetual/assets/down.png"),
	lcd_start = ContentLoader._load("res://themes/perpetual/assets/lcd/lcd_start.png"),
	lcd_inf = ContentLoader._load("res://themes/perpetual/assets/lcd/lcdnoreset.png"),
	lcd_clock = ContentLoader._load("res://themes/perpetual/assets/lcd/lcdtimer.png")
}

var timer_scene = ContentLoader._load("res://Timer.tscn")
var integer_input_scene = ContentLoader._load("res://IntegerComponent.tscn")

var timer_icons = [
	ContentLoader._load("res://themes/perpetual/assets/lcd/lcdminus.png"),
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

func __update_option(menu: SContextMenu, index, info, value) -> void:
	if info.type == "toggle":
		menu.set_item_icon(index, icons.checked if value else icons.unchecked)
	elif info.type == "radio":
		for option in info.options.size():
			menu.get_node(menu.get_item_submenu(index)).set_item_icon(option, icons.radio if value == option else icons.unradio)
	

func __add_option(menu: SContextMenu, id, info, value):
	var index = menu.item_count
	if info.type == "toggle":
		menu.add_item(info.name)
		menu.set_item_icon(index, icons.checked if value else icons.unchecked)
	elif info.type == "radio":
		var submenu = SContextMenu.new(
			"blah",
			func(click_id: int, _menu: SContextMenu): # just discard the extra arg, we dont need it!!!!!!!!
				Logger.info(click_id)
				var entity = Data.entities[current_entity]
				entity.options[id] = click_id
				entity.update_mesh()
				__update_option(menu, index, info, value),
			menu
		)
		submenu.set_name(id)
		
		#submenu.id_pressed.connect(func(click_id):
			#var entity = Data.entities[current_entity]
			#entity.options[id] = click_id
			#entity.update_mesh()
			#__update_option(menu, index, info, value)
		#)
		
		for option in info.options.size():
			submenu.add_item(info.options[option], option)
			submenu.set_item_icon(submenu.item_count - 1, icons.unradio)
		submenu.set_item_icon(value, icons.radio)
		
		submenu.titlebar_visible = false
		
		#submenu.popup_window = false
		
		#menu.add_child(submenu)
		menu.add_submenu(info.name, id)
	elif info.type == "timer":
		var timer = timer_scene.instantiate()
		timer.name = str(id)
		timer.position = Vector2(24, index * 28 + 4)
		
		timer.set_value(value)
		
		menu.add_child(timer)
		menu.add_item("")
		menu.set_item_icon(index, icons.up)
		menu.add_item("")
		menu.set_item_icon(index+1, icons.down)
	elif info.type == "integer":
		var timer = integer_input_scene.instantiate()
		timer.name = str(id)
		timer.position = Vector2(24, index * 28 + 4)
		
		timer.set_value(value)
		
		timer.set_icon(Util.has(info, "icon", "blank"))
		
		menu.add_child(timer)
		menu.add_item("")
		menu.set_item_icon(index, icons.up)
		menu.add_item("")
		menu.set_item_icon(index+1, icons.down)
	return index

func _click(id: int, menu: SContextMenu):
	var entity = Data.entities[current_entity]
	var entity_info = Data.registered_entities[entity.name]
	
	var current_option = current_options[id]
	
	var close_on_click = true
	
	if current_option.type == "option":
		var editor_info = entity_info.editor.options[current_option.option]
		var type = editor_info.type
		close_on_click = false
		if type == "toggle":
			entity.options[current_option.option] = !entity.options[current_option.option]
			#set_item_checked(id, entity.options[current_option.option])
		elif type == "timer":
			if current_option.mode == "add":
				entity.options[current_option.option] += 1
			else:
				entity.options[current_option.option] -= 1
			entity.options[current_option.option] = clamp(entity.options[current_option.option], 0, 9999)
			menu.get_node(current_option.option).set_value(entity.options[current_option.option])
		elif type == "integer":
			if current_option.mode == "add":
				entity.options[current_option.option] += Util.has(editor_info, "step", 1)
			else:
				entity.options[current_option.option] -=  Util.has(editor_info, "step", 1)
			entity.options[current_option.option] = clamp(entity.options[current_option.option], Util.has(editor_info, "min", 0), Util.has(editor_info, "max", 99))
			menu.get_node(current_option.option).set_value(entity.options[current_option.option])
		entity.update_mesh()
	elif current_option.type == "delete":
		Entities._remove_entity(current_entity)
	elif current_option.type == "connect":
		Selection.link_info.type = "connection"
		
		if Util.has(entity_info.export.connections, "inputs", {}).size() > 1 or Util.has(entity_info.export.connections, "outputs", {}).size() > 1:
			# we need to find out which connection they want
			Connections.prompt_link_type(current_entity, func(con) -> void:
				Selection.link_info.connection_id = con.id
				for type in Selection.link_info.connections:
					Selection.link_info.connections[type] = type == con.type
				Selection.link_item = Entities.get_node(str(current_entity))
			)
		else:
			Selection.link_item = Entities.get_node(str(current_entity))
			Selection.link_info.connections.input = entity_info.export.connections.has("inputs")
			Selection.link_info.connections.output = entity_info.export.connections.has("outputs")
	if close_on_click:
		menu.hide()
	else:
		__update_option(menu, id, Data.registered_entities[entity.name].editor.options[current_option.option], entity.options[current_option.option])

func _show(entity):
	Util.play_sound("other_explo")
	current_entity = entity
	entity = Data.entities[entity]
	var entity_info = Data.registered_entities[entity.name]
	
	var menu: SContextMenu = SContextMenu.new(entity_info.name.to_upper(), _click, get_tree().root.get_node("Spatial/UI"))
	menu.hide_on_checkable_item_selection = false
	menu.hide_on_item_selection = false
	menu.hide_on_state_item_selection = false
	
	menu.popup_hide.connect(func():
		Util.play_sound("other_collapse")
		menu.queue_free()
	)
	
	current_options = {}
	
	if entity_info.export.has("connections"):
		current_options[menu.item_count] = {type = "connect"}
		menu.add_item("Connect to...")
		current_options[menu.item_count] = {type = "disconnect"}
		var submenu = PopupMenu.new()
		submenu.set_name("disconnect")
		
		var connections: Array[int] = []
		
		submenu.id_pressed.connect(func(click_id):
			Connections.unlink(connections[click_id])
			menu.hide()
		)
		
		for con in entity.connections.outputs:
			submenu.add_item(Data.registered_entities[Data.entities[con.target].name].name)
			submenu.set_item_icon(menu.item_count - 1, icons.empty)
			connections.append(int(con.id))
		for con in entity.connections.inputs:
			submenu.add_item(Data.registered_entities[Data.entities[con.target].name].name)
			submenu.set_item_icon(menu.item_count - 1, icons.empty)
			connections.append(int(con.id))
		
		menu.add_child(submenu)
		menu.add_submenu("Remove connections", "disconnect")
		menu.set_item_disabled(menu.item_count-1, connections.size() == 0)
	for id in entity.options:
		var index = __add_option(menu, id, entity_info.editor.options[id], entity.options[id])
		if entity_info.editor.options[id].type == "timer" or entity_info.editor.options[id].type == "integer":
			current_options[index] = {type = "option", option = id, mode = "add"}
			current_options[index + 1] = {type = "option", option = id, mode = "subtract"}
		else:
			current_options[index] = {type = "option", option = id}
	menu.add_separator()
	
	current_options[menu.item_count] = {type = "delete"}
	
	menu.add_item("Delete item")
	menu.set_item_disabled(menu.item_count - 1, entity_info.editor.locked)
	menu.set_item_icon(menu.item_count - 1, icons.empty)
	
	menu.set_tween()

func _show_surface(voxel, surface):
	current_voxel = voxel

func _hide():
	Logger.error("_hide is deprecated!")

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_hide()
