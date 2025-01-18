class_name Surface

enum {
	NONE = -1,
	NEGATIVE_Y,
	POSITIVE_Y,
	NEGATIVE_Z,
	POSITIVE_Z,
	NEGATIVE_X,
	POSITIVE_X
}

var value: int
var normal: Vector3 : get = _get_normal

func _init(direction: int = 0) -> void:
	value = direction

static func from_normal(normal: Vector3) -> Surface:
	var instance = Surface.new(NONE)
	if normal.y == 1:
		instance.value = POSITIVE_Y
	elif normal.y == -1:
		instance.value = NEGATIVE_Y
	elif normal.z == 1:
		instance.value = POSITIVE_Z
	elif normal.z == -1:
		instance.value = NEGATIVE_Z
	elif normal.x == 1:
		instance.value = POSITIVE_X
	elif normal.x == -1:
		instance.value = NEGATIVE_X
	return instance

func is_positive() -> bool:
	return value % 2 == 0

func _get_normal() -> Vector3:
	return round(-to_basis().y)

func to_basis() -> Basis:
	match value:
		POSITIVE_Y:
			return Basis(Vector3(1,0,0),PI) * Basis(Vector3(0,1,0),PI/2)
		NEGATIVE_Y:
			return Basis(Vector3(0,1,0),0) * Basis(Vector3(0,1,0),PI/2)
		POSITIVE_Z:
			return Basis(Vector3(1,0,0),PI*1.5)
		NEGATIVE_Z:
			return Basis(Vector3(1,0,0),PI/2) * Basis(Vector3(0,1,0),PI)
		POSITIVE_X:
			return Basis(Vector3(0,0,1),PI/2) * Basis(Vector3(0,1,0),PI/2)
		NEGATIVE_X:
			return Basis(Vector3(0,0,1),PI*1.5) * Basis(Vector3(0,1,0),-PI/2)
		_:
			return Basis()
