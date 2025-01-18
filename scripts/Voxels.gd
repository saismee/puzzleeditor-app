extends MeshInstance3D

var voxels: Dictionary = {}
var old_voxels: Dictionary = {}

var voxel_queue: Array = []

@onready var Connections: Control = get_tree().get_root().get_node("Spatial/UI/Connections")
@onready var Entities: MeshInstance3D = get_node("../Entities")

var generating: bool = false

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var original_state: int = 0

var planes: Dictionary = {
	"up": {
		"vertices": PackedVector3Array([
			Vector3(1,0,0),
			Vector3(1,0,1),
			Vector3(0,0,0),
			Vector3(0,0,0),
			Vector3(1,0,1),
			Vector3(0,0,1),
		]),
		"uv": PackedVector2Array([
			Vector2(1,0),
			Vector2(1,1),
			Vector2(0,0),
			Vector2(0,0),
			Vector2(1,1),
			Vector2(0,1),
		])
	},
	"down": {
		"vertices": PackedVector3Array([
			Vector3(0,0,0),
			Vector3(1,0,1),
			Vector3(1,0,0),
			Vector3(0,0,1),
			Vector3(1,0,1),
			Vector3(0,0,0),
		]),
		"uv": PackedVector2Array([
			Vector2(0,0),
			Vector2(1,1),
			Vector2(1,0),
			Vector2(0,1),
			Vector2(1,1),
			Vector2(0,0),
		])
	},
	"left": {
		"vertices": PackedVector3Array([
			Vector3(1,0,0),
			Vector3(0,1,0),
			Vector3(0,0,0),
			Vector3(1,0,0),
			Vector3(1,1,0),
			Vector3(0,1,0),
		]),
		"uv": PackedVector2Array([
			Vector2(1,0),
			Vector2(0,1),
			Vector2(0,0),
			Vector2(1,0),
			Vector2(1,1),
			Vector2(0,1),
		])
	},
	"right": {
		"vertices": PackedVector3Array([
			Vector3(0,0,0),
			Vector3(0,1,0),
			Vector3(1,0,0),
			Vector3(0,1,0),
			Vector3(1,1,0),
			Vector3(1,0,0),
		]),
		"uv": PackedVector2Array([
			Vector2(0,0),
			Vector2(0,1),
			Vector2(1,0),
			Vector2(0,1),
			Vector2(1,1),
			Vector2(1,0),
		])
	},
	"forward": {
		"vertices": PackedVector3Array([
			Vector3(0,0,1),
			Vector3(0,1,0),
			Vector3(0,0,0),
			Vector3(0,0,1),
			Vector3(0,1,1),
			Vector3(0,1,0),
		]),
		"uv": PackedVector2Array([
			Vector2(0,1),
			Vector2(1,0),
			Vector2(0,0),
			Vector2(0,1),
			Vector2(1,1),
			Vector2(1,0),
		])
	},
	"backward": {
		"vertices": PackedVector3Array([
			Vector3(0,0,0),
			Vector3(0,1,0),
			Vector3(0,0,1),
			Vector3(0,1,0),
			Vector3(0,1,1),
			Vector3(0,0,1),
		]),
		"uv": PackedVector2Array([
			Vector2(0,0),
			Vector2(1,0),
			Vector2(0,1),
			Vector2(1,0),
			Vector2(1,1),
			Vector2(0,1),
		])
	}
}

var axes: Array = [
	Vector3(0,-1,0),
	Vector3(0,1,0),
	Vector3(0,0,-1),
	Vector3(0,0,1),
	Vector3(-1,0,0),
	Vector3(1,0,0),
]

var materials: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_project()

func new_project() -> void:
	rng.randomize()
	original_state = rng.state
	
	_clear()
	
#	for x in range(0,8):
#		for y in range(0,4):
#			for z in range(0,6):
#				set_voxel(Vector3(x, y, z), false)
	set_voxel(Vector3(0, 0, 0), false)
	
	if !get_tree().root.is_node_ready():
		await get_tree().root.ready
	
	open_project(ContentLoader._loadjson("res://maps/blank.json"))
	Connections.queue_regen()

func _format_project(dict: Dictionary) -> Dictionary:
	var out: Dictionary = {
		"voxels": {},
		"entities": [],
		"connections": dict.connections
	}
	
	for index in dict.voxels:
		var new_index = Util.parse_vector(index)
		out.voxels[new_index] = {"surfaces":{}}
		if dict.voxels[index].surfaces is Array:
			for surface: int in dict.voxels[index].surfaces.size():
				var surface_info = dict.voxels[index].surfaces[surface]
				surface_info.erase("visible")
				out.voxels[new_index].surfaces[surface] = surface_info
		else: # handle old save files which use a dictionary
			for surface: String in dict.voxels[index].surfaces:
				var surface_info: Dictionary = dict.voxels[index].surfaces[surface]
				out.voxels[new_index].surfaces[surface.to_int()] = surface_info
	for index in dict.entities.size():
		if dict.entities[index] == null:
			out.entities.insert(index, null)
			continue
		var entity: Dictionary = JSON.parse_string(dict.entities[index])
		var new_entity: Entity = Entity.new(
			entity.name,
			Util.parse_vector(entity.position),
			Surface.new(entity.surface),
			Util.parse_vector(entity.rotation)
		)
		
		var registered_entity = Data.registered_entities[entity.name]
		#Logger.info(registered_entity)
		
		# get default options and check if the saved data has them
		for option in Util.has(registered_entity.editor, "options", {}):
			new_entity.options[option] = Util.has(Util.has(entity, "options", {}), option, registered_entity.editor.options[option].value)
		
		# do the same for handles
		for handle in Util.has(registered_entity.editor, "handles", {}):
			new_entity.handles[handle] = Util.has(Util.has(entity, "handles", {}), handle, registered_entity.editor.handles[handle].value)
		
		new_entity.connections = entity.connections
		
		out.entities.insert(index, new_entity)
	return out

func open_project(data: Dictionary) -> void:
	_clear()
	Entities._clear()
	Connections.clear()
	var out = _format_project(data)
	
	if data.has("seed") and data.has("state"):
		rng.seed = data.seed
		rng.state = data.state
		original_state = data.state
	else:
		rng.randomize()
		original_state = rng.state
	
	Data.voxels = {}
	for vec: Vector3i in out.voxels:
		Data.voxels[vec] = Voxel.new(self, vec, false)
		for key in out.voxels[Vector3(vec)].surfaces:
			Data.voxels[vec].surfaces[key] = out.voxels[Vector3(vec)].surfaces[key]
		voxel_queue.append(vec)
	
	Data.entities = out.entities
	
	for index in Data.entities.size():
		if Data.entities[index] == null: continue
		var entity: Entity = Data.entities[index]
		for option in entity.options:
			if !Data.registered_entities[entity.name].editor.options.has(option):
				Data.entities[index].options.erase(option)
				# this might be obsolete, check
		
		for option in Data.registered_entities[entity.name].editor.options:
			if !Data.entities[index].options.has(option):
				Data.entities[index].options[option] = Data.registered_entities[entity.name].editor.options[option].value
				# this might be obsolete, check
	
	
	Data.connections = Util.has(out, "connections", 0)
	
	Entities._generate_entities()

func save_project(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	var entities: Array[Variant] = []
	for index in Data.entities.size():
		var entity = Data.entities[index]
		if entity == null:
			entities.append(null);
			return
		entities.append(entity._to_string())
	
	var voxels: Dictionary = {}
	for index: Vector3i in Data.voxels:
		voxels[index] = Data.voxels[index].serialize()
	
	file.store_string(JSON.new().stringify({
		"voxels": voxels,
		"entities": entities,
		"seed": rng.seed,
		"state": original_state,
		"connections": Data.connections
	}))
	file.close()

func _clear() -> void:
	Data.voxels = {}
	for node in get_children():
		remove_child(node)
		node.queue_free()

func flip_portalability(pos: Vector3i, target_surface: int = -1) -> void:
	var voxel = _get_voxel(pos)
	if !voxel: return
	if target_surface == -1:
		for surface: int in 6:
			voxel.surfaces[surface].portalable = !voxel.surfaces[surface].portalable
	else:
		var surfaces = voxel.surfaces
		surfaces[target_surface].portalable = !surfaces[target_surface].portalable
	Data.voxels[pos].update_materials()

func set_portalability(pos: Vector3i, target_surface: int = -1, value: bool = true) -> void:
	var voxel = _get_voxel(pos)
	if !voxel: return
	if target_surface == -1:
		for surface: int in 6:
			voxel.surfaces[surface].portalable = value
	else:
		var surfaces = voxel.surfaces
		surfaces[target_surface].portalable = value
	Data.voxels[pos].update_materials()

func _get_voxel(vector: Vector3i) -> Variant: # returns null or the voxel
	if Data.voxels.has(vector):
		return Data.voxels[vector]
	return null

func _add_voxel(vector: Vector3i, portalable: Variant, no_spread: bool = true) -> void:
	#Data.voxels[vector] = {
		#"surfaces": {}
	#}
	#for index in range(0,6):
		#Data.voxels[vector].surfaces[index] = {
			#"portalable": portalable
		#}
	#Logger.info(vector)
	if Data.voxels.has(vector): return
	Data.voxels[Vector3i(vector)] = Voxel.new(self, vector, portalable)
	_update_voxel(vector, no_spread)
	Connections.invalidate()

func set_voxel(vector: Vector3i, portalable: bool = false) -> void:
	if Data.voxels.has(vector): return
	Data.voxels[Vector3i(vector)] = Voxel.new(self, vector, portalable)
	_update_voxel(vector, true)
	#Data.voxels[voxel] = {
		#"surfaces": {}
	#}
	#for index in range(0,6):
		#Data.voxels[voxel].surfaces[index] = {
			#"portalable": portalable
		#}
	#_update_voxel(voxel, true)
	Connections.invalidate()
	  
func _remove_voxel(vector: Vector3i) -> void:
	if !Data.voxels.has(vector): return
	#Data.voxels[vector].destroy()
	Data.voxels[vector].queue_free()
	Data.voxels.erase(Vector3i(vector))
	_update_voxel(vector, false)
	Connections.invalidate()

func _update_voxel(vector: Vector3i, no_spread: bool = true) -> void:
	#voxel_queue.append(vector)
	if Data.voxels.has(vector):
		Data.voxels[vector].update()
	
	if no_spread:
		return
	for axis in axes:
		var pos: Vector3i = vector + Vector3i(axis)
		if !Data.voxels.has(pos): continue
		Data.voxels[pos].update()
		#voxel_queue.append(vector+axis)

func _dict_random(dict: Dictionary) -> Variant: #TODO: move to util?
	var out = dict.keys()
	return dict[out[rng.randi() % out.size()]]

var last_con_regen: int = 0 # why is this here? TODO: move to connections or further up in the code?
var con_latest: bool = false
var con_ready: bool = false

func _process(delta: float) -> void:
	if generating: return
	
	if voxel_queue.size() > 0:
		#Logger.info(voxel_queue.size())
		#if Time.get_ticks_msec() > 1000:
			#for index in voxel_queue.size():
				#Util.add_helper("voxel" + str(index), voxel_queue[index])
			#voxel_queue = []
			#return
		con_ready = false
		generating = true
		for index: Vector3i in voxel_queue:
			Data.voxels[index].update()
			#var voxel: Vector3 = voxel_queue[index]
			#_render_voxel(voxel)
			#if Data.voxels.has(voxel):
				#Connections.updated_voxels.append(voxel)
		voxel_queue = []
		generating = false
		con_latest = false
	else:
		con_ready = true
	#
	if (Time.get_ticks_msec() > last_con_regen + 1000) and !con_latest and con_ready:
		last_con_regen = Time.get_ticks_msec()
		con_latest = true

var updating: bool = false # TODO: move up
