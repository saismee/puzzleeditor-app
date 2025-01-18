extends Node

var export_normals = [
	Vector3(0,-1,0),
	Vector3(0,1,0),
	Vector3(-1,0,0),
	Vector3(1,0,0),
	Vector3(0,0,-1),
	Vector3(0,0,1),
]

var surface_normals = [
	Vector3(0,-1,0),
	Vector3(0,1,0),
	Vector3(0,0,-1),
	Vector3(0,0,1),
	Vector3(-1,0,0),
	Vector3(1,0,0),
]
var surface_orientations = [
	Basis(Vector3(0,1,0),0) * Basis(Vector3(0,1,0),PI/2),
	Basis(Vector3(1,0,0),PI) * Basis(Vector3(0,1,0),PI/2),
	Basis(Vector3(1,0,0),PI/2) * Basis(Vector3(0,1,0),PI),
	Basis(Vector3(1,0,0),PI*1.5),# * Basis(Vector3(0,1,0),-PI),
	Basis(Vector3(0,0,1),PI*1.5) * Basis(Vector3(0,1,0),-PI/2),
	Basis(Vector3(0,0,1),PI/2) * Basis(Vector3(0,1,0),PI/2),
]

var surface_adjacents = [
	{x = Vector3(0, 0, 1), z = Vector3(1, 0, 0)}, # 0
	{x = Vector3(0, 0, 1), z = Vector3(1, 0, 0)}, # 1
	{x = Vector3(0, 0, 1), z = Vector3(0, 1, 0)}, # 2
	{x = Vector3(0, 0, 1), z = Vector3(0, 1, 0)}, # 3
	{x = Vector3(1, 0, 0), z = Vector3(0, 1, 0)}, # 4
	{x = Vector3(1, 0, 0), z = Vector3(0, 1, 0)}, # 5
]

var export_orientations = [
	Basis(Vector3(0,0,1),-PI/2),
	Basis(Vector3(0,0,1),PI/2) * Basis(Vector3(0,1,0),PI),
	Basis(Vector3(1,0,0),PI/2),
	Basis(Vector3(1,0,0),PI*1.5) * Basis(Vector3(0,1,0),-PI),
	Basis(Vector3(0,0,1),PI*1.5) * Basis(Vector3(0,1,0),PI/2),
	Basis(Vector3(0,0,1),PI/2) * Basis(Vector3(0,1,0),-PI/2),
]

var export_offsets = [
	Vector3.ZERO,
	Vector3(0, -1, 0),
	Vector3.ZERO,
	Vector3(0, 0, -1),
	Vector3.ZERO,
	Vector3(-1, 0, 0),
]

var embed_offsets = [
	Vector3.ZERO,
	Vector3(1, 0, 0),
	Vector3.ZERO,
	Vector3(1, 0, 0),
	Vector3(1, 0, 0),
	Vector3.ZERO,
]

var brush_export_offsets = [
	Vector3(0, 1, 0),
	Vector3(0, 0, 1),
	Vector3(0, 0, 1),
	Vector3(1, 0, 0),
	Vector3(1, 0, 1),
	Vector3(0, 0, 0)
]

var audio_streams = {}

func perpendicular_vector(vec: Vector3) -> Vector3:
	return vec.abs().normalized() * -1 + Vector3(1, 1, 1)

func translate_relative(origin: Basis, translation: Vector3) -> Vector3:
	# takes a vector3 and moves it relative to the basis' rotation
	return origin.x * -translation.x + origin.y * translation.y + origin.z * translation.z

func parse_vector(vector: String, delimiter: String = ",") -> Vector3:
	var array = vector.trim_prefix("(").trim_suffix(")").split(delimiter)
	return Vector3(array[0].to_float(),array[1].to_float(),array[2].to_float())

func has(dict, key, default):
	if dict.has(key): return dict[key]
	return default

func iterate_dir(path: String, function: Callable) -> Variant:
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	var val = dir.get_next()
	while val != "":
		var out = function.call(val)
		if out != null:
			return out
		val = dir.get_next()
	return null

func copy_dir(from: String, to: String) -> void:
	Logger.info(from + str(DirAccess.dir_exists_absolute(from)))
	if DirAccess.dir_exists_absolute(from):
		if !DirAccess.dir_exists_absolute(to): DirAccess.make_dir_recursive_absolute(to)
		iterate_dir(from, func(name: String) -> void:
			copy_dir(from + "\\" + name, to + "\\" + name)
		)
	else: # must be a file\
		var out := FileAccess.open(to, FileAccess.WRITE)
		out.store_buffer(FileAccess.get_file_as_bytes(from))
		out.close()
		#DirAccess.copy_absolute(from, to)

func vector3_component_min(v1: Vector3, v2: Vector3) -> Vector3:
	return Vector3(min(v1.x, v2.x), min(v1.y, v2.y), min(v1.z, v2.z))

func vector3_component_max(v1: Vector3, v2: Vector3) -> Vector3:
	return Vector3(max(v1.x, v2.x), max(v1.y, v2.y), max(v1.z, v2.z))

func vector3_component_lte(v1: Vector3, v2: Vector3) -> bool:
	return (v1.x <= v2.x) and (v1.y <= v2.y) and (v1.z <= v2.z)

func vector3_component_gte(v1: Vector3, v2: Vector3) -> bool:
	return (v1.x >= v2.x) and (v1.y >= v2.y) and (v1.z >= v2.z)

func iterate_bounds(start: Vector3, end: Vector3, function: Callable) -> Variant:
	var low: Vector3 = vector3_component_min(start, end)
	var high: Vector3 = vector3_component_max(start, end)
	var is_broken = false
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			for z in range(low.z, high.z + 1):
				is_broken = function.call(Vector3(x, y, z))
				if is_broken: return is_broken
	return false

func add_helper(name: String, pos: Vector3, rot: Basis = Basis.from_euler(Vector3.ZERO), parent: Node = get_tree().root.get_child(0)) -> void:
	var obj
	if !get_tree().root.get_child(0).has_node(name):
		obj = MeshInstance3D.new()
		obj.name = name
		obj.mesh = ContentLoader._load("res://meshes/3dsel.obj")
		parent.add_child(obj)
	
	if obj == null:
		obj = get_tree().root.get_child(0).get_node(name)
	
	rot = rot.scaled(Vector3(0.5, 0.5, 0.5))
	
	obj.position = pos
	obj.basis = rot
	
#	Util.add_helper(pos + Util.surface_normals[0] + Vector3(0.5, 0.5, 0.5))

func closest_point_on_line(points: Array[Vector3], start: Vector3, end: Vector3) -> int:
	var closest: int = -1
	var closest_dist: float = 99999
	
	Debug.add_node("a", start)
	Debug.add_node("a", end)
	
	for index: int in points.size():
		var line_dir := (end - start).normalized()
		var point_dir := points[index] - start
		var dist := line_dir.dot(point_dir)
		Logger.info(points[index])
		
		if dist < closest_dist:
			closest = index
			closest_dist = dist
	
	return closest

static var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _load_audio_stream(path: String) -> AudioStreamPlayer:
	var stream = AudioStreamPlayer.new()
	stream.set_stream(ContentLoader._load(path))
	get_tree().root.add_child(stream)
	return stream

func play_sound(name: String) -> void:
	if !audio_streams.has(name):
		if DirAccess.dir_exists_absolute("res://sounds/" + name):
			Logger.info("Loading sound directory: " + name)
			audio_streams[name] = []
			iterate_dir(
				"res://sounds/" + name,
				func(sound_name: String) -> void:
					if !sound_name.ends_with(".wav.import"): return
					Logger.info("Loading sound file: " + name + "/" + sound_name)
					audio_streams[name].append(_load_audio_stream("res://sounds/" + name + "/" + sound_name.left(len(sound_name) - len(".import"))))
			)
		else:
			Logger.info("Loading sound: " + name)
			audio_streams[name] = _load_audio_stream("res://sounds/" + name + ".wav")
	
	if audio_streams[name] is Array:
		audio_streams[name][rng.randi() % max(audio_streams[name].size(), 1)].play()
	else:
		audio_streams[name].play()
