extends MeshInstance3D

const surface_extrusion: Array = [
	Vector3(0,-1,0),
	Vector3(0,1,0),
	Vector3(0,0,-1),
	Vector3(0,0,1),
	Vector3(-1,0,0),
	Vector3(1,0,0),
]

@onready var Voxels: MeshInstance3D = get_node("../Voxels")
@onready var Entities: MeshInstance3D = get_node("../Entities")
@onready var Camera: Camera3D = get_node("../Camera")
@onready var Connections: Control = get_tree().root.get_node("Spatial/UI/Connections")
@onready var SelectionRenderer: Control = get_tree().root.get_node("Spatial/UI/SelectionRenderer")

@onready var sel_material: Material = ContentLoader._load("res://materials/depthsel.tres")

var selection_start: Vector3 = Vector3(0,0,0)
var selection_end: Vector3 = Vector3(0,0,0)
var selection_surface: Surface = Surface.new(0)

var selection_entity_index = null
var selection_entity_object = null

var selection_handle: Node = null
var selection_handle_parent: Node = null

@onready var mesh_2d: ArrayMesh = ContentLoader._load("res://meshes/selection.obj")
@onready var mesh_3d: ArrayMesh = ContentLoader._load("res://meshes/3dsel.obj")

var mdt: MeshDataTool = MeshDataTool.new()

var link_info: Dictionary = {
	type = "connection",
	connections = {
		output = false,
		input = false
	},
	connection_id = "default",
	target = null
}
var link_item = null
var link_valid: bool = false

func rescale(size: Vector3, is_3d: bool = false) -> void:
	mdt.create_from_surface(mesh_3d if is_3d else mesh_2d, 0)
	for index: int in mdt.get_vertex_count():
		var pos: Vector3 = mdt.get_vertex(index)
		mdt.set_vertex(index, pos + Vector3(
			(size.x - 1) * (0.5 if pos.x > 0 else -0.5),
			(size.y - 1) * (0.5 if pos.y > 0 else -0.5),
			(size.z - 1) * (0.5 if pos.z > 0 else -0.5)
		))
	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
	pass

func update_selection_bounds(start: Vector3, end: Vector3, end_surface: Surface) -> void:
	var surface = end_surface.value
	if selection_surface.value != end_surface.value:
		surface = Surface.NONE
	match surface:
		Surface.POSITIVE_Y, Surface.NEGATIVE_Y:
			rescale(Vector3(
				abs(start.z-end.z)+1,
				1,
				abs(start.x-end.x)+1
			))
		Surface.POSITIVE_Z, Surface.NEGATIVE_Z:
			rescale(Vector3(
				abs(start.x-end.x)+1,
				1,
				abs(start.y-end.y)+1
			))
		Surface.POSITIVE_X, Surface.NEGATIVE_X:
			rescale(Vector3(
				abs(start.z-end.z)+1,
				1,
				abs(start.y-end.y)+1
			))
		_:
			basis = Basis()
			rescale((start-end).abs() + Vector3.ONE, true)
	position = (start + end)/2 + Vector3(0.5,0.5,0.5)

func _select(voxel: Vector3, surface: Surface, silent: bool = false) -> void:
#	Logger.info(surface)
	if selection_entity_object and is_instance_valid(selection_entity_object):
#		selection_entity_object.get_node("outline").visible = false
		#selection_entity_object.material_override = null
		Data.entities[selection_entity_object.name.to_int()].deselect()
		selection_entity_object = null
	selection_entity_index = null
	
	selection_start = voxel
	selection_end = voxel
	selection_surface = surface
	position = voxel + Vector3(0.5,0.5,0.5) #the mesh is centred, but the voxels are offset
	basis = surface.to_basis()
	
	set_selection_end(selection_end, surface)
	if !silent: Util.play_sound("tile_pick")
	
	#mesh = ContentLoader._load("res://meshes/selection.obj")
	
	#this fixes the offset problem

func _end_select(voxel: Vector3, surface: Surface, silent: bool = false) -> void:
	selection_end = voxel
	if surface.value != selection_surface.value:
		selection_surface = Surface.new(Surface.NONE)
		surface = selection_surface
	SelectionRenderer.set_selection_bounds(selection_start, voxel, surface)
	if !silent:
		if selection_end == selection_start: return
		Util.play_sound("tile_pick")
	#transform.origin = (selection_start + selection_end)/2 + Vector3(0.5,0.5,0.5) #centre the selection between the two points

func set_selection_end(voxel: Vector3, surface: Surface) -> void:
	#update_selection_bounds(selection_start, voxel, surface)
	if surface.value != selection_surface.value:
		surface = Surface.new(Surface.NONE)
	SelectionRenderer.set_selection_bounds(selection_start, voxel, surface)

func _select_entity(index: Variant) -> void:
	selection_entity_index = index
	if selection_entity_index == null: return
	if selection_entity_object and is_instance_valid(selection_entity_object):
		#selection_entity_object.material_override = null
		# TODO: kinda obsolete
		
		Data.entities[selection_entity_object.name.to_int()].deselect()
		selection_entity_object = null
	
	selection_entity_object = get_node("../Entities/" + str(selection_entity_index))
#	selection_entity_object.get_node("outline").visible = true
	Data.entities[index].select()
	#selection_entity_object.material_override = sel_material

func select_handle(handle: Node, entity: int) -> void:
	if handle:
		selection_handle = handle
		selection_handle_parent = get_node("../Entities/" + str(entity))
		Logger.info("selected handle " + str(handle.name))
	else:
		selection_handle = null
		#_select_entity(selection_handle_parent.name.to_int())
		Data.entities[selection_handle_parent.name.to_int()].select()
		selection_handle_parent = null

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if !event.pressed: return
		var sel_min: Vector3 = Util.vector3_component_min(selection_start, selection_end)
		var sel_max: Vector3 = Util.vector3_component_max(selection_start, selection_end)
		if event.keycode == KEY_P:
			var is_portalable: bool = false
			if selection_surface.value == Surface.NONE:
				is_portalable = Util.iterate_bounds(selection_start, selection_end, func(pos: Vector3):
					var voxel = Voxels._get_voxel(pos)
					if !voxel: return
					for surface: int in 6:
						if voxel.surfaces[surface].portalable:
							return true # break!
				)
			else:
				is_portalable = Util.iterate_bounds(selection_start, selection_end, func(pos: Vector3):
					if Voxels._get_voxel(pos).surfaces[selection_surface.value].portalable:
						return true # break!
				)
			Util.iterate_bounds(selection_start, selection_end, func(pos: Vector3):
				Voxels.set_portalability(pos, selection_surface.value, !is_portalable)
			)
		elif event.keycode == KEY_MINUS:
			if selection_surface.value == Surface.NONE:
				Util.iterate_bounds(selection_start, selection_end, func(pos: Vector3):
					Voxels._add_voxel(pos, false, false)
				)
			else:
				Util.iterate_bounds(selection_start, selection_end, func(pos: Vector3):
					var voxel: Variant = Voxels._get_voxel(pos) # Dictionary | null
					if !voxel: return
					Voxels._add_voxel(pos + selection_surface.normal, voxel.surfaces[selection_surface.value].portalable, false)
					Voxels._update_voxel(pos, true)
				)
				
				for index in Data.entities.size():
					var entity: Entity = Data.entities[index]
					if !entity: continue
					if entity.surface.value != selection_surface.value: continue
					var pos: Vector3 = entity.position
					if !selection_surface.is_positive():
						pos -= surface_extrusion[selection_surface.value]
					if !Util.vector3_component_gte(pos, sel_min): continue
					if !Util.vector3_component_lte(pos, sel_max): continue
					entity.position += surface_extrusion[selection_surface.value]
					Connections.recalculate_entity(index, true)
				
				var end = selection_end + selection_surface.normal
				_select(selection_start + selection_surface.normal,selection_surface, true)
				_end_select(end,selection_surface, true)
				Util.play_sound("extrude")
		elif event.keycode == KEY_EQUAL:
			if selection_surface.value == Surface.NONE:
				pass
			else:
				Util.iterate_bounds(selection_start, selection_end, func(pos: Vector3):
					if Data.voxels.has(Vector3i(pos)):
						Voxels._remove_voxel(pos)
						#Voxels._update_voxel(pos, false)
				)
				
				for index in Data.entities.size():
					var entity: Entity = Data.entities[index]
					if !entity: continue
					if entity.surface.value != selection_surface.value: continue
					var pos: Vector3 = entity.position
					if !selection_surface.is_positive():
						pos -= selection_surface.normal
					if !Util.vector3_component_gte(pos, sel_min): continue
					if !Util.vector3_component_lte(pos, sel_max): continue
					entity.position -= selection_surface.normal
					Connections.recalculate_entity(index, true)
				
				var end = selection_end - selection_surface.normal
				_select(selection_start - selection_surface.normal, selection_surface, true)
				_end_select(end,selection_surface, true)
				Util.play_sound("carve")
	elif event is InputEventMouseMotion and event.relative.length_squared() > 0:
		if selection_handle:
			Camera.get_nearest_handle(selection_handle_parent, selection_handle_parent.name.to_int(), selection_handle.name)
			return
		
		if selection_entity_index != null:
			var surface_info = Camera.get_surface(1/Data.grid_size)
			if surface_info:
				var entity = Data.entities[selection_entity_index]
				
				if entity.position == surface_info.voxel: return

				var pos = surface_info.voxel
				var rot = surface_info.surface.to_basis().get_euler()
				if Util.has(Data.registered_entities[entity.name].editor, "forced_rotation", false):
					rot = Util.parse_vector(Data.registered_entities[entity.name].editor.forced_rotation) * PI
				#entity.position = pos - (Data.registered_entities[entity.name].editor.size * Util.perpendicular_vector(Util.surface_normals[surface_info.surface])) / 2
				entity.surface = surface_info.surface
				entity.position = pos + (
					- Util.translate_relative(surface_info.surface.to_basis(), Data.registered_entities[entity.name].editor.size/2)
					* Util.perpendicular_vector(surface_info.surface.to_basis().y)
				).snapped(Vector3(0.25, 0.25, 0.25))
				entity.rotation = floor(rot / (PI/180))
				
#				Util.add_helper("_ent_sel", pos + Util.translate_relative(Util.surface_orientations[surface_info.surface], Vector3(0, 1, 0)) + Vector3(0.5, 0.5, 0.5), Util.surface_orientations[surface_info.surface])
#				Util.add_helper("_ent_sel", pos, Util.surface_orientations[surface_info.surface])
#				Logger.info(surface_info.surface)
				
#				selection_entity_object.position = pos + Vector3(0.5, 0.5, 0.5)
#				selection_entity_object.rotation = rot
				Connections.recalculate_entity(selection_entity_index, true)
		elif link_item != null:
			link_valid = false
			var surface_info = Camera._get_selected_surface()
			if surface_info and surface_info.entity != null:
				var entity = Data.entities[surface_info.entity]
				link_info.target = surface_info.entity
				var entity_info = Data.registered_entities[entity.name]
				if !entity_info.export.has("connections"): return
				if entity_info.export.connections.has("inputs") and link_info.connections.output:
					link_valid = true
					return
				if entity_info.export.connections.has("outputs") and link_info.connections.input:
					link_valid = true
					return
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if link_item and link_valid and (link_info.target != null):
				# we should now have a valid link with a valid target
				# do a quick comparison to ensure we're connecting correctly!
				var entity = Data.entities[link_info.target]
				var entity_info = Data.registered_entities[entity.name]
				if (link_info.connections.output and Util.has(entity_info.export.connections, "inputs", {}).size() > 1) or (link_info.connections.input and Util.has(entity_info.export.connections, "outputs", {}).size() > 1):
					Connections.prompt_link_type(int(link_info.target), func(con) -> void:
						# link it
						if con.type == "output":
							Connections.link(int(link_info.target), int(str(link_item.name)), con.id, link_info.connection_id)
							# OUTPUT, INPUT
						else:
							Connections.link(int(str(link_item.name)), int(link_info.target), link_info.connection_id, con.id)
							# OUTPUT, INPUT
						link_item = null
					, "inputs" if link_info.connections.output else "outputs")
				else:
					#ok lets determine which is in, and which is out
					if link_info.connections.output: # target is input
						Connections.link(int(str(link_item.name)), int(link_info.target), link_info.connection_id)
					else: # target is output
						Connections.link(int(link_info.target), int(str(link_item.name)), null, link_info.connection_id)
					link_item = null
			else:
				link_item = null
