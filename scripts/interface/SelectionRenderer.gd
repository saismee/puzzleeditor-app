extends CanvasItem

@onready var Camera = get_tree().root.get_node("Spatial/Camera")

var sel_surface: Surface = Surface.new()
var sel_start: Vector3 = Vector3.ZERO
var sel_end: Vector3 = Vector3.ZERO

const color: Color = Color("FEE545")
const color2: Color = Color("604511")

const colors = {
	highlight = Color("FEE545"),
	voxel = Color("604511"),
	voxel_dark = Color("60451110")
}

const points: Array = [
	Vector3(0, 0, 0), Vector3(1, 0, 0),
	Vector3(0, 0, 0), Vector3(0, 1, 0),
	Vector3(0, 0, 0), Vector3(0, 0, 1),
	
	Vector3(1, 1, 1), Vector3(0, 1, 1),
	Vector3(1, 1, 1), Vector3(1, 0, 1),
	Vector3(1, 1, 1), Vector3(1, 1, 0),
	
	Vector3(1, 0, 0), Vector3(1, 1, 0),
	Vector3(1, 0, 0), Vector3(1, 0, 1),
	
	Vector3(0, 1, 0), Vector3(1, 1, 0),
	Vector3(0, 1, 0), Vector3(0, 1, 1),
	
	Vector3(0, 0, 1), Vector3(1, 0, 1),
	Vector3(0, 0, 1), Vector3(0, 1, 1),
]

var offset: Vector3 = Vector3.ONE / 50

func unproject(pos: Vector3) -> Vector2i:
	return Camera.unproject_position(pos)

func component_const_lerp(start: Vector3, end: Vector3, alpha: Vector3, value: int = 1) -> Vector3:
	# takes an array of 3 bools and returns a vector3i with each component being from start if false, and end if true
	return Vector3(
		end.x if alpha[0] == value else start.x,
		end.y if alpha[1] == value else start.y,
		end.z if alpha[2] == value else start.z
	)

func _draw() -> void:
	#Logger.info([sel_surface, Surface.NONE])
	#if sel_surface == Surface.NONE:
	var perpendicular: Vector3 = Vector3.ONE
	if sel_surface.value != Surface.NONE:
		perpendicular = (Util.perpendicular_vector(sel_surface.normal))# - (Vector3.ZERO if sel_surface.is_positive() else Vector3.ONE)).abs()\
	
	var value: int = 1 if sel_surface.is_positive() else 0
	
	for index: int in range(0, points.size(), 2):
		draw_line(
			unproject(component_const_lerp(sel_start + offset, sel_end - offset, points[index] * perpendicular, value)),
			unproject(component_const_lerp(sel_start + offset, sel_end - offset, points[index + 1] * perpendicular, value)),
			colors.highlight, -1, true
		)
		draw_line(
			unproject(component_const_lerp(sel_start - offset, sel_end + offset, points[index] * perpendicular, value)),
			unproject(component_const_lerp(sel_start - offset, sel_end + offset, points[index + 1] * perpendicular, value)),
			colors.highlight, -1, true
		)
		draw_line(
			unproject(component_const_lerp(sel_start, sel_end, points[index], value)),
			unproject(component_const_lerp(sel_start, sel_end, points[index + 1], value)),
			colors.voxel if sel_surface.value == Surface.NONE else colors.voxel_dark, -1, true
		)
	#draw_line(unproject(sel_start), unproject(sel_end), color, 4, true)
	#else:
		#pass

func set_selection_bounds(start: Vector3i, end: Vector3i, surface: Surface) -> void:
	var middle: Vector3 = (start + end) / 2
	
	sel_surface = surface
	sel_start = Util.vector3_component_min(start, end)
	sel_end = Vector3i(Util.vector3_component_max(start, end)) + Vector3i(1, 1, 1)

func _process(delta: float) -> void:
	queue_redraw()
