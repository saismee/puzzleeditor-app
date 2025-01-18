extends MeshInstance3D

@onready var Selection = get_node("../Selection")
@onready var Handles = get_node("../Handles")
@onready var Ribbon = get_tree().root.get_node("Spatial/UI/Ribbon")

func _check_validity(index):
	return true # todo: implement validity checking

func _clear():
	Selection._select_entity(null)
	Selection.selection_entity_index = null
	Selection.selection_entity_object = null
	Data.entities = []
	for node in get_children():
		remove_child(node)
		node.queue_free()

func _generate_entities():
	Logger.info("Generating entities")
	Logger.info(Data.entities.size())
	for index in Data.entities.size():
		if Data.entities[index] == null: continue
		_generate_entity(index)

func generate_handle(entity: Entity, name: String, info: Dictionary, parent: Node) -> void:
	Logger.info("Generating handle: " + name)
	
	var points: Array[Vector3] = []
	
	for index in info.positions.size():
		#Logger.info(info.positions[index])
		points.append(info.positions[index])
		#Util.add_helper("handle_" + name + str(index), points[index], Basis.from_scale(Vector3(0.5, 0.5, 0.5)), parent)
	
	#Util.add_helper("handle_" + name, points[info.value], Basis.from_scale(Vector3(1, 1, 1)), parent)
	
	var mesh = Util.has(info, "mesh", ContentLoader._load("res://meshes/missing.obj"))
	
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.name = name
	node.position = points[info.value]
	node.create_convex_collision(false, false)
	
	node.add_to_group("handle")
	
	parent.add_child(node)

func _generate_entity(index):
	var entity = Data.entities[index]
	
	if !Data.registered_entities.has(entity.name):
		Logger.warn(entity.name + " is missing!")
		SPopup.new("Entity missing", entity.name + " is missing!\nDid you remove a package?", "Ignore")
		return
	
	var mesh = Util.has(Util.has(Data.registered_entities[entity.name], "editor", {}), "mesh", ContentLoader._load("res://meshes/missing.obj"))
#	var mesh = ContentLoader._load("res://meshes/pos.obj")
	var outlinemesh = mesh.create_outline(0.05)
	outlinemesh.surface_set_material(0, ContentLoader._load("res://materials/depthsel.tres"))
	
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.name = str(index)
	node.create_convex_collision(false, false)
	
	var outline = MeshInstance3D.new()
	outline.name = "outline"
	outline.mesh = outlinemesh
	outline.visible = false
	node.add_child(outline)
	#TODO: obsolete?
	
	var handles_object := Node3D.new()
	handles_object.name = "handles"
	handles_object.visible = false
	#node.add_child(handles_object)
	
	entity.object = node
	entity.handle_object = handles_object
	Handles.add_child(handles_object)
	
	entity.update_mesh()
	
	var valid = _check_validity(index)
	
	add_child(node)
	
	#Logger.info(Data.registered_entities[entity.name].editor.handles)
	
	#for handle_name in Data.registered_entities[entity.name].editor.handles:
		#Logger.info(Data.registered_entities[entity.name].editor.handles[handle_name])
		#generate_handle(entity, handle_name, Data.registered_entities[entity.name].editor.handles[handle_name], handles_object)

func create_entity(id: String, surface: Surface, pos: Vector3, rot: Vector3) -> int:
	Logger.check(Data.registered_entities.has(id), id + " is not a valid entity!")
	var entity_info = Data.registered_entities[id]
	
	if entity_info.has("editor") and entity_info.editor.has("limit"):
		if count_entity(id) >= int(entity_info.editor.limit):
			SPopup.new("Item Limit Reached", "You cannot have more than " + str(entity_info.editor.limit) + " of this item.")
			return -1
	
	var new_entity = Entity.new(id, pos, surface, rot)
	
	if entity_info.has("editor") and entity_info.editor.has("options"):
		for index in entity_info.editor.options:
			new_entity.options[index] = entity_info.editor.options[index].value
	
	if entity_info.has("editor") and entity_info.editor.has("handles"):
		for index in entity_info.editor.handles:
			new_entity.handles[index] = entity_info.editor.handles[index].value
	
	Data.entities.append(new_entity)
	return Data.entities.size()-1

func clone_entity(id: int) -> void:
	if Util.has(Data.registered_entities[Data.entities[id].name].editor, "locked", false): return
	var entity: Entity = Data.entities[id]
	var new_entity: int = create_entity(entity.name, entity.surface, entity.position + Vector3(0.5, 0.5, 0.5), entity.rotation)
	if new_entity == 01: return
	
	for option in Data.entities[id].options:
		Data.entities[new_entity].options[option] = Data.entities[id].options[option]
	for handle in Data.entities[id].handles:
		Data.entities[new_entity].handles[handle] = Data.entities[id].handles[handle]
		
	_generate_entity(new_entity)
	Selection._select_entity(new_entity)

func count_entity(entity_name: String) -> int:
	var count: int = 0
	for entity: Entity in Data.entities:
		if entity == null: continue
		if entity.name != entity_name: continue
		count += 1
	return count

func _remove_entity(id):
	if Util.has(Data.registered_entities[Data.entities[id].name].editor, "locked", false): return
	Handles.remove_child(Data.entities[id].handle_object)
	Data.entities[id].handle_object.queue_free()
	Data.entities[id] = null
	var node = get_node(str(id))
	if node == Selection.selection_entity_object:
		Selection.selection_entity_object = null
	remove_child(node)
	node.queue_free()

func _input(event):
	if Selection.selection_entity_object == null: return
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_C:
			clone_entity(Selection.selection_entity_object.name.to_int())
		elif event.keycode == KEY_DELETE:
			_remove_entity(Selection.selection_entity_object.name.to_int())
