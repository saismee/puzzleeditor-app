extends CanvasItem

@onready var Selection = get_tree().root.get_node("Spatial/Selection")
@onready var Entities = get_tree().root.get_node("Spatial/Entities")
@onready var Camera = get_tree().root.get_node("Spatial/Camera")

var regen_required: bool = false
var regen_thread: Thread

var astar: Pathfinder = Pathfinder.new(8.0)

var updated_voxels: Array[Vector3]

var connections = {}

func _draw() -> void:
	if Selection.link_item != null:
		var origin = Camera.unproject_position(Selection.link_item.position).round()
		var target = get_viewport().get_mouse_position().round()
		
		var col = Color("36EBFF") if Selection.link_valid else Color("286A6F")
		
		draw_line(origin, Vector2(target.x, origin.y), col, 2, false)
		draw_line(Vector2(target.x, origin.y - 1), target - Vector2(0, 8), col, 2, false)
		
		if Selection.link_valid:
			draw_rect(Rect2(target - Vector2(8, 8), Vector2(16, 16)), col)
			draw_rect(Rect2(origin - Vector2(6, 6), Vector2(12, 12)), col)
		else:
			draw_rect(Rect2(target - Vector2(6, 6), Vector2(12, 12)), col, false, 2)
			
	for con in connections.values():
		for point in con.size():
#			draw_rect(Rect2(Camera.unproject_position(con[point]) - Vector2(6, 6), Vector2(12, 12)), Color(con[point].x / 8, con[point].y / 8, con[point].z / 8))
			if con.size() > point + 1:
				draw_line(Camera.unproject_position(con[point]), Camera.unproject_position(con[point + 1]), Color("FF0000"), 4)

func clear() -> void:
	connections.clear()

func prompt_link_type(ent: int, function: Variant = null, show_type: Variant = null):
	var entity = Data.entities[ent]
	var entity_info = Data.registered_entities[entity.name]
	var cons = []
	var menu = SContextMenu.new(entity_info.name.to_upper() + " CONNECTION", func(id: int, menu: SContextMenu) -> void:
		if function != null:
			function.call(cons[id])
	, get_tree().root.get_node("Spatial/UI"))
	# create the menu, then add the i/o
	if entity_info.export.connections.has("inputs") and (show_type == null or show_type == "inputs"):
		for input in entity_info.export.connections.inputs:
			menu.add_item("Input: " + entity_info.export.connections.inputs[input].name)
			cons.append({
				type = "input",
				id = input
			})
	if entity_info.export.connections.has("outputs") and (show_type == null or show_type == "outputs"):
		for output in entity_info.export.connections.outputs:
			menu.add_item("Output: " + entity_info.export.connections.outputs[output].name)
			cons.append({
				type = "output",
				id = output
			})
	menu.set_tween()

func link(ent1: int, ent2: int, con1: Variant = null, con2: Variant = null) -> void:
	# display a little heart to indicate.
	Logger.info("Created connection between " + str(ent1) + " and " + str(ent2))
	Logger.info("Connection ID: " + str(Data.connections))
	# assume the connection is OUTPUT -> INPUT
	# example: FLOOR_BUTTON -> EXIT_DOOR
	var entity1: Entity = Data.entities[ent1]
	var entity2: Entity = Data.entities[ent2]
	var entity1_info: Dictionary = Data.registered_entities[entity1.name]
	var entity2_info: Dictionary = Data.registered_entities[entity2.name]
	# pain
	entity1.connections.outputs.append({
		target = ent2,
		type = con1 if con1 != null else "default",
		id = Data.connections
	})
	entity2.connections.inputs.append({
		target = ent1,
		type = con2 if con2 != null else "default",
		id = Data.connections
	})
	Data.connections += 1
	
#	generate_connection(Entities.get_node(str(ent1)).position + Util.surface_normals[entity1.surface]/2, Entities.get_node(str(ent2)).position + Util.surface_normals[entity2.surface]/2)
	
	recalculate_connections()
	
	Util.play_sound("connect")

func unlink(connection_id: int) -> void:
	for entity_id: int in Data.entities.size():
		var entity: Entity = Data.entities[entity_id]
		entity.unlink_connection(connection_id)
	
	connections.erase(connection_id)
	
	recalculate_connections()
	
	Util.play_sound("connect")

func generate_connection(point1: Vector3, point2: Vector3, id: int = connections.size()) -> void:
	var path = astar.get_path(point1, point2)
	var con = []
	Logger.info(path)
	for point in path:
		con.append(astar.get_point_position(point))
	connections[id] = con

func invalidate() -> void:
	regen_required = true

var voxels_list: Array[Variant] = []
var voxels_output: PackedVector3Array = []

var mutex: Mutex

func _process_voxel(task_index: int) -> void:
	var index: Vector3i = voxels_list[task_index]
	var voxel: Voxel = Data.voxels[index]
	
	var my_voxels: PackedVector3Array
	
	
	for surface_index in 6:
		var surface: Vector3 = Surface.new(surface_index).normal
		var new_index: Vector3 = Vector3(index) + surface
		if !Data.voxels.has(Vector3i(new_index)):
			# no voxel = a surface!
			var gridsize: float = astar.gridsize
			var perp: Vector3 = Util.perpendicular_vector(surface)
			var perpgrid: Vector3 = Util.perpendicular_vector(surface) * gridsize
			for x in range(max(perpgrid.x, 1)):
				for y in range(max(perpgrid.y, 1)):
					for z in range(max(perpgrid.z, 1)):
						var pos: Vector3 = new_index + Vector3(0.5, 0.5, 0.5) - perp/2 + perp/(gridsize*2) - surface/2 + Vector3(x/gridsize, y/gridsize, z/gridsize)
						#astar.add(pos)
						if my_voxels.has(pos): continue
						my_voxels.append(pos)
						# something about this math seems really scarily wrong but it works so i dont know honestly
	mutex.lock()
	voxels_output += my_voxels
	mutex.unlock()

func queue_regen(full: bool = false) -> void:
	regen_required = false
	var start_time: float = Time.get_ticks_usec()
	Logger.info("Starting recalculating connection geometry...")
	
	voxels_list.clear()
	voxels_output.clear()
	for pos in Data.voxels:
		voxels_list.append(pos)
	
	Logger.info(voxels_list.size())
	mutex = Mutex.new()
	var task_id: int = WorkerThreadPool.add_group_task(_process_voxel, voxels_list.size())

	WorkerThreadPool.wait_for_group_task_completion(task_id)
	Logger.info("Finished recalculating connection geometry (1)...")
	Logger.info("Time taken to recalculate connections (1): " + str((Time.get_ticks_usec() - start_time) * 1e-6) + " seconds")
	astar.reset()
	for pos in voxels_output:
		#Debug.add_node(str(pos), pos, Basis.from_scale(Vector3(0.25, 0.25, 0.25)))
		astar.add(pos)
	Logger.info("Finished recalculating connection geometry (2)...")
	recalculate_connections()
	Logger.info("Finished recalculating connection geometry (3)...")
	Logger.info("Time taken to recalculate connections: " + str((Time.get_ticks_usec() - start_time) * 1e-6) + " seconds")

func recalculate_entity(index: int, check_inputs: bool = false) -> void:
	var entity1 = Data.entities[index]
	if !entity1: return
	for output in entity1.connections.outputs:
		var entity2 = Data.entities[output.target]
		if !entity2: continue
		generate_connection(
			Entities.get_node(str(index)).position + entity1.surface.normal/2,
			Entities.get_node(str(output.target)).position + entity2.surface.normal/2,
			output.id
		)
	if !check_inputs: return
	for input in entity1.connections.inputs:
		recalculate_entity(input.target)

func recalculate_connections() -> void:
	for index in Data.entities.size():
		recalculate_entity(index)

#func _ready() -> void:
	#queue_regen()

func _process(delta: float) -> void:
	if regen_required:
		queue_regen()
#	if Selection.link_item != null:
	queue_redraw()
