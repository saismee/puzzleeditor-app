extends Camera3D

@onready var Selection = get_node("../Selection")
@onready var Entities = get_node("../Entities")
@onready var ContextMenu = get_tree().root.get_node("Spatial/UI/ContextMenu")

var focus = Vector3(4,2,3)
var distance = 20
var rot_x = 15
var rot_y = 20

var sensitivity = 0.15
var pansensitivity = 0.025

var middle_mouse_down
var left_mouse_down
var selection_dragging: bool = false
var right_mouse_down

var double_click: bool = false

var mouse_delta = Vector2(0,0)

var surface_expansion = [
	[Vector3.RIGHT, Vector3.BACK],
	[Vector3.RIGHT, Vector3.BACK],
	[Vector3.RIGHT, Vector3.UP],
	[Vector3.RIGHT, Vector3.UP],
	[Vector3.UP, Vector3.BACK],
	[Vector3.UP, Vector3.BACK],
]

#var target_object

var Voxels

# Called when the node enters the scene tree for the first time.
func _ready():
	#target_object = find_node("Target")
	Voxels = get_tree().current_scene.find_child("Voxels")

func _process(delta):
	var new_transform = Transform3D(Basis(),Vector3.ZERO)
	new_transform = new_transform.rotated(Vector3(1,0,0),-rot_y * PI/180)
	new_transform = new_transform.rotated(Vector3(0,1,0),-rot_x * PI/180)
	new_transform.origin = focus
	new_transform.origin += new_transform.basis.z * distance
	transform = new_transform
	
	#target_object.transform = Transform(Basis(),focus)

func get_surface(scale: float = 1.0) -> Variant:
	var mouse_pos = get_viewport().get_mouse_position()
	var origin = project_ray_origin(mouse_pos)
	var direction = origin + project_ray_normal(mouse_pos) * 100
	
	var param = PhysicsRayQueryParameters3D.new()
	param.set_hit_back_faces(false)
	param.set_hit_from_inside(false)
	
	var exclusion_list = []
	for entity in get_node("../Entities").get_children():
		exclusion_list.append(entity.get_child(0))
	param.collision_mask = 2
#	param.set_exclude(exclusion_list)
#	param.set
	
	param.from = origin
	param.to = direction
	var hit = get_world_3d().direct_space_state.intersect_ray(param)
	if hit:
		var pos = hit.position + hit.normal*0.1
		var voxel = Vector3(round(pos.x * scale) / scale, round(pos.y * scale) / scale, round(pos.z * scale) / scale)
		var surface = Surface.from_normal(-hit.normal)
		
		return {
			"voxel":voxel,
			"surface":surface,
		}
	return null

func _get_selected_surface():
	var mouse_pos = get_viewport().get_mouse_position()
	var origin = project_ray_origin(mouse_pos)
	var direction = origin + project_ray_normal(mouse_pos) * 100
	var param = PhysicsRayQueryParameters3D.new()
	param.set_hit_back_faces(false)
	param.set_hit_from_inside(false)
	param.from = origin
	param.to = direction
	var hit = get_world_3d().direct_space_state.intersect_ray(param)
	if hit:
		var pos = hit.position + hit.normal*0.1 # i dont really know what this does
		var voxel = Vector3(floor(pos.x),floor(pos.y),floor(pos.z))
		
		var surface: Surface = Surface.from_normal(-hit.normal)
		
		var entity: Variant = null # TODO: Node?
		var handle: Variant = null # TODO: Node?
		if hit.collider.find_parent("Handles"):
			handle = hit.collider.get_parent()
			entity = hit.collider.get_parent().get_meta("entity")
		elif hit.collider.find_parent("Entities"):
			#var parent: Node = hit.collider.get_parent()
			#if parent.is_in_group("handle"):
				#handle = hit.collider.get_parent()
				#entity = hit.collider.get_parent().get
			#else:
			entity = hit.collider.get_parent().name.to_int()
		
		return { # maybe this could be changed to some type shit?
			"voxel":voxel,
			"surface":surface,
			"entity":entity,
			"handle":handle
		}
	return

func get_nearest_handle(entity: Node, entity_index: int, handle_name: String) -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	
	var handle_object: Node = Data.entities[entity.name.to_int()].handle_object
	
	# TODO: CHECK ROTATABLE
	
	var points: Array = Data.registered_entities[Data.entities[entity_index].name].editor.handles[handle_name].positions
	
	var closest_point: int = -1
	var closest_dist: float = 9999999
	
	var basis: Basis = entity.basis
	if Util.has(Data.registered_entities[Data.entities[entity_index].name].editor.handles[handle_name], "rotatable", true) == false:
		Logger.info("NOT ROTATABLE")
		basis = handle_object.basis
	
	for index in points.size():
		var dist: float = (mouse_pos - unproject_position(handle_object.position + Util.translate_relative(basis, Vector3(-points[index].x, points[index].y, points[index].z)))).length_squared()
		Debug.add_node(str(index) + "ejfhwdcuih", handle_object.position + Util.translate_relative(basis, Vector3(-points[index].x, points[index].y, points[index].z)))
		if dist < closest_dist:
			closest_dist = dist
			closest_point = index
	
	if closest_point != Data.entities[entity_index].handles[handle_name]:
		Data.entities[entity_index].set_handle(handle_name, closest_point)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
#		if event.relative.length() > 1:
			if selection_dragging and !double_click:
				if Selection.selection_entity_object: return
				if Selection.selection_handle: return
				var surface_info = _get_selected_surface()
				if surface_info == null: return
				Selection.set_selection_end(surface_info.voxel, surface_info.surface)
			elif middle_mouse_down:
				rot_x += event.relative.x * sensitivity
				rot_y += event.relative.y * sensitivity
			elif right_mouse_down:
				focus += (-transform.basis.x) * (event.relative.x * pansensitivity * (distance / 50.0))
				#print(transform.basis.z, transform.basis.y)
				#focus += (-transform.basis.z) * event.relative.x * pansensitivity
				focus += transform.basis.y * (event.relative.y * pansensitivity * (distance / 50.0))
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			middle_mouse_down = event.pressed
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			right_mouse_down = event.pressed
			if !event.pressed:
				var surface_info = _get_selected_surface()
				if surface_info == null: return
				
				if surface_info.entity != null:
#					var entity_info = Entities.valid_entities[Entities.entities[surface_info.entity].name]
#					ContextMenu._load_options(
#						entity_info.name,
#						entity_info.options if entity_info.has("options") else null,
#						entity_info.locked if entity_info.has("locked") else false
#					)
					ContextMenu._show(surface_info.entity)
#			else:
#				Logger.info("clic")
#				ContextMenu._hide()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = min(distance * 1.1,100)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = max(distance / 1.1,3)
			
		elif event.button_index == MOUSE_BUTTON_LEFT:
			left_mouse_down = event.pressed
			if !event.pressed:
				selection_dragging = false
			if Selection.link_item != null: return
			if event.double_click:
				double_click = true # prevent end selection from fucking it up
				var surface_info = _get_selected_surface()
				var expansion_info = surface_expansion[surface_info.surface]
				var first_voxel = surface_info.voxel
				
				var negative_pos: Vector3 = surface_info.voxel
				var positive_pos: Vector3 = surface_info.voxel
				
				var xexpand = surface_expansion[surface_info.surface][0]
				var yexpand = surface_expansion[surface_info.surface][1]
				
				var x: int = 1
				var y: int = 1
				
				while true:
					var broken: bool = true
					
					x += 1
					
					if Voxels._get_voxel(negative_pos - xexpand):
						negative_pos -= xexpand
						broken = false
					if Voxels._get_voxel(positive_pos + xexpand):
						positive_pos += xexpand
						broken = false
					if broken: break
				
				while true:
					var broken: bool = true
					
					y += 1
					
					if Voxels._get_voxel(negative_pos - yexpand):
						negative_pos -= yexpand
						broken = false
					if Voxels._get_voxel(positive_pos + yexpand):
						positive_pos += yexpand
						broken = false
					if broken: break
				
				Selection._select(negative_pos,surface_info.surface)
				Selection._end_select(positive_pos,surface_info.surface)
			elif event.pressed:
				var surface_info = _get_selected_surface()
				if surface_info == null:
					middle_mouse_down = true
					return
				
				if (surface_info.entity != null) and (surface_info.handle == null):
					Selection._select_entity(surface_info.entity)
				elif (surface_info.handle):
					Selection.select_handle(surface_info.handle, surface_info.entity)
				else:
					Selection._select(surface_info.voxel,surface_info.surface)
					selection_dragging = true
			else:
				middle_mouse_down = false
				if double_click:
					double_click = false
					return
				if Selection.selection_entity_index != null:
					Selection._select_entity(null) # finish entity selection by selecting nothing
					return
				if Selection.selection_handle != null:
					Selection.select_handle(null, 0)
					return
				
				var surface_info = _get_selected_surface()
				if surface_info == null: return
				Selection._end_select(surface_info.voxel,surface_info.surface)
