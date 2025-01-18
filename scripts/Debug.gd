extends Node
#@onready var Camera = get_tree().root.get_node("Spatial/Camera")

var col := Color("36EBFF")

var lines: Dictionary = {}

func add_node(name: String, pos: Vector3, rot: Basis = Basis.from_euler(Vector3.ZERO), parent: Node = get_tree().root.get_child(0)) -> void:
	var obj: MeshInstance3D
	if !parent.has_node(name):
		obj = MeshInstance3D.new()
		obj.name = name
		obj.mesh = ContentLoader._load("res://meshes/3dsel.obj")
		parent.add_child(obj)
	
	if obj == null:
		obj = parent.get_node(name)
	
	rot = rot.scaled(Vector3(0.5, 0.5, 0.5))
	
	obj.position = pos
	obj.basis = rot

func add_line(name: String, start: Vector3, end: Vector3, parent: Node = get_tree().root.get_child(0)) -> Mesh:
	var obj: MeshInstance3D
	var mesh: BoxMesh = BoxMesh.new()
	if !parent.has_node(name):
		obj = MeshInstance3D.new()
		obj.name = name
		parent.add_child(obj)
	
	if obj == null:
		obj = parent.get_node(name)
	
	obj.position = (start + end) / 2
	obj.basis = Basis().looking_at(start - end)
	mesh.size = Vector3(0.02, 0.02, (start - end).length())
	mesh.flip_faces = true
	
	obj.mesh = mesh
	
	return mesh

func remove_line(name: String, parent: Node = get_tree().root.get_child(0)) -> void:
	if parent.has_node(name):
		var obj: MeshInstance3D = parent.get_node(name)
		parent.remove_child(obj)
		obj.queue_free()
