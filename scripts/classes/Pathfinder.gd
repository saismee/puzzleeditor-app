class_name Pathfinder extends AStar3D

const diagonals: Array[Vector3] = [
	Vector3(1, 1, 0),
	Vector3(-1, 1, 0),
	Vector3(1, -1, 0),
	Vector3(-1, -1, 0),
	
	Vector3(1, 0, 1),
	Vector3(-1, 0, 1),
	Vector3(1, 0, -1),
	Vector3(-1, 0, -1),
	
	Vector3(0, 1, 1),
	Vector3(0, -1, 1),
	Vector3(0, 1, -1),
	Vector3(0, -1, -1)
]

var normals: Array[Vector3] = [
	Vector3(0,-1,0),
	Vector3(0,1,0),
	Vector3(0,0,-1),
	Vector3(0,0,1),
	Vector3(-1,0,0),
	Vector3(1,0,0),
]

var points: Dictionary
var gridsize: float

func _init(gridsize: float = 1.0) -> void:
	self.points = {}
	self.gridsize = gridsize

func reset() -> void:
	self.points = {}
	clear()

func _compute_cost(u: int, v: int) -> float:
	var pos1 = get_point_position(u)
	var pos2 = get_point_position(v)
	
	var cost = abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y) + abs(pos1.z - pos2.z)
	cost *= get_point_weight_scale(u) * get_point_weight_scale(v)
	
	if pos1.x != pos2.x: cost *= 2
	if pos1.y != pos2.y: cost *= 4
	if pos1.z != pos2.z: cost *= 3
	
#	var vec = (pos1-pos2)
#	Logger.info(str(pos1) + " " + str(pos2) + " " + str(vec))
#	Logger.info(str(vec.angle_to(_prev_vec)))
#	Logger.info(are_points_connected(u, v))
#	var cost = vec.distance_to(_prev_vec)
#	costs[u] = [v, cost]
#	self._u = pos1
#	self._v = pos2
#	self._prev_vec = vec
#	var cost = pos1.distance_to(pos2)
	return cost

func _estimate_cost(u: int, v: int) -> float:
	var pos1 = get_point_position(u)
	var pos2 = get_point_position(v)
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y) + abs(pos1.z - pos2.z)
#	return 1.0
#	return min(0, await _compute_cost(u, v) - 0.1)

func add(pos: Vector3, weight: float = 1.0) -> void:
	if points.has(pos):
		return
	var index: int = points.size()
	points[pos] = {
		index = index,
		weight = weight
	}
	add_point(index, pos, weight)
	
	for normal in normals:
		var target: Vector3 = pos + (normal / gridsize)
		if !points.has(target): continue
		if index == points[target].index: continue
		connect_points(index, points[target].index)
	for diag in diagonals:
		var target: Vector3 = (pos + diag / gridsize / 2)
		if !points.has(target): continue
		if index == points[target].index: continue
		connect_points(index, points[target].index)

func get_path(pos1: Vector3, pos2: Vector3) -> Array:
	return get_id_path(get_closest_point(pos1), get_closest_point(pos2))

func get_connections(pos: Vector3) -> Array:
	var connections = get_point_connections(points[pos].index)
	var out = []
	for con in connections:
		out.append(get_point_position(con))
	return out
