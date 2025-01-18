extends GraphEdit

var entities: Array[String] = []
var nodes: Array[String] = []
var current_entity: String = ""

var recurse_index: int = 0

var valid_nodes: Dictionary = {
	"switch": {
		"type": "switch",
		"key": "",
		"results": {
			"0": []
		}
	},
	"add_instance": {
		"type": "add_instance",
		"instance": ""
	},
	"add_overlay": {
		"type": "add_overlay",
		"instance": ""
	},
	"embed_volume": {
		"type": "embed_volume",
		"start": "(0,0,0)",
		"end": "(0,0,0)"
	}
}

func _ready() -> void:
	add_valid_right_disconnect_type(0)
	
	var entities_button = get_node("../Ribbon/Entities")
	var entities_popup = entities_button.get_popup()
	entities_popup.id_pressed.connect(func(id):
		current_entity = entities[id]
		clear_connections()
		for node in get_children():
			remove_child(node)
			node.queue_free()
		recurse_index = 0
		load_graph(Data.registered_entities[current_entity].export.conditions)
		arrange_nodes()
	)
	var nodes_button = get_node("../Ribbon/AddNode")
	var nodes_popup = nodes_button.get_popup()
	nodes_popup.id_pressed.connect(func(id):
		_recurse_graph(valid_nodes[nodes[id]])
	)
	
	delete_nodes_request.connect(func(nodes: Array[StringName]) -> void:
		for node in nodes:
			get_node(str(node)).queue_free()
	)
	
	update_entities()
	update_nodes()
	current_entity = "tractor_beam"
	#Logger.info(Data.registered_entities[current_entity].export.conditions)
	load_graph(Data.registered_entities[current_entity].export.conditions)
	arrange_nodes()

func exit() -> void:
	get_parent().visible = false

func _get_connection(to_node: String, to_port: int) -> Dictionary:
	var connections: Array = get_connection_list()
	Logger.info(to_node)
	Logger.info(to_port)
	return {} # TODO

func save() -> void:
	var out: String = ""
	
	var connections = get_connection_list()
	
	var nodes: Dictionary = {}
	for node in get_children():
		nodes[node.name] = {
			type = node.title,
		}
		var children: Array[Node] = node.get_children()
		for child_index in range(0, children.size()): # skip the titlebar and parent field
			var child: Node = children[child_index]
			Logger.info(child.get_children())
			if !(child is HBoxContainer): continue
			var key_node: LineEdit = child.get_node("key")
			var value_node: LineEdit = child.get_node("value")
			if nodes[node.name].has(key_node.text):
				if !(nodes[node.name][key_node.text] is Dictionary):
					nodes[node.name][key_node.text] = {nodes[node.name][key_node.text]: _get_connection(node.name, 0)}
				nodes[node.name][key_node.text][value_node.text] = nodes[node.name][key_node.text].size()
			else:
				nodes[node.name][key_node.text] = value_node.text
	Logger.info(nodes)
	
	
	DisplayServer.clipboard_set(JSON.new().stringify(nodes))

func _connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	for con in get_connection_list():
		if con.to_node == to_node and con.to_port == to_port:
			return
	connect_node(from_node, from_port, to_node, to_port)

func _disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	disconnect_node(from_node, from_port, to_node, to_port)

#func _connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	#for con in get_connection_list():
		#if con.from_node != from_node: continue
		#if con.from_port != from_port: continue
		#disconnect_node(from_node, from_port, con.to_node, con.to_port)
		#return

func _recurse_graph(graph: Variant, depth: int = 0, width: int = 0, parent: Variant = null, port: Variant = 0) -> void:
	recurse_index += 1
	if typeof(graph) == TYPE_ARRAY:
		for index in graph.size():
			_recurse_graph(graph[index], depth, width + index, parent, port)
	elif typeof(graph) == TYPE_DICTIONARY:
		match graph.type:
			"switch":
				var node: CESwitchNode = CESwitchNode.new(graph.type, Vector2i(-depth * 150, width * 250), self)
				node.name = str(recurse_index)
				
				node.add_control("parent")
				node.set_slot_enabled_right(0, true)
				if parent:
					connect_node(node.name, 0, parent.name, port)
				node.add_string_control("key", graph.key)
				#node.set_slot_enabled_left(0, true)
				
				for index in graph.results:
					node.add_case(index)
					recurse_index += 1
					_recurse_graph(graph.results[index], 0, 0, node, node.case_count - 1)
			"add_instance":
				var node: CEBaseNode = CEBaseNode.new(graph.type, Vector2i(-depth * 150, width * 250), self)
				node.name = str(recurse_index)
				
				node.add_control("parent")
				node.set_slot_enabled_right(0, true)
				if parent:
					connect_node( node.name, 0, parent.name, port)
				node.add_string_control("instance", graph.instance)
				node.add_string_control("position", Util.has(graph, "position", ""))
				node.add_string_control("global_position", Util.has(graph, "global_position", ""))
				
				#if !graph.has("fixups"): return
				#node.add_control("fixups", false)
				#var int_index: int = 0
				#for index in graph.fixups:
					#node.add_control(index, false)
					#if typeof(graph.fixups[index]) == TYPE_DICTIONARY:
						#var results: Dictionary = {}
						#_recurse_graph({
							#"type": "switch",
							#"key": graph.fixups[index].key,
							#"results": graph.fixups[index].results
						#}, depth - 1, width)
			"add_overlay":
				var node: CEBaseNode = CEBaseNode.new(graph.type, Vector2i(-depth * 150, width * 250), self)
				node.name = str(recurse_index)
				
				node.add_control("parent")
				node.set_slot_enabled_right(0, true)
				if parent:
					connect_node( node.name, 0, parent.name, port)
				node.add_string_control("instance", graph.instance)
			"embed_volume":
				var node: CEBaseNode = CEBaseNode.new(graph.type, Vector2i(-depth * 150, width * 250), self)
				node.name = str(recurse_index)
				
				node.add_control("parent")
				node.set_slot_enabled_right(0, true)
				if parent:
					connect_node( node.name, 0, parent.name, port)
				node.add_string_control("start", Util.has(graph, "start", ""))
				node.add_string_control("end", Util.has(graph, "end", ""))

func load_graph(graph: Array) -> void:
	recurse_index = 0
	_recurse_graph(graph)

func update_entities() -> void:
	entities = []
	var entities_button = get_node("../Ribbon/Entities")
	var popup = entities_button.get_popup()
	popup.clear()
	for entity in Data.registered_entities:
		popup.add_item(Data.registered_entities[entity].name)
		popup.set_item_icon(popup.item_count - 1, ContentLoader._load("res://themes/perpetual/assets/empty.png"))
		entities.append(entity)
	current_entity = entities[0]

func update_nodes() -> void:
	nodes = []
	var nodes_button = get_node("../Ribbon/AddNode")
	var popup = nodes_button.get_popup()
	popup.clear()
	for node in valid_nodes:
		popup.add_item(node)
		popup.set_item_icon(popup.item_count - 1, ContentLoader._load("res://themes/perpetual/assets/empty.png"))
		nodes.append(node)
