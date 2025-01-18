class_name SurfaceSolid2 extends SourceGD.BaseSolid

var surface_axes = [
	["y", "x", "z"],
	["y", "x", "z"],
	["x", "y", "z"],
	["x", "y", "z"],
	["z", "x", "y"],
	["z", "x", "y"]
]

func _init(position: Vector3, size: Vector3, materials: Array, surface: int, indent: int = 8) -> void:
	position = Vector3(position.z, position.y, position.x)
	
	var target = position
	
	if surface % 2 == 1:
		target = position + size/2
	else:
		target = position - size/2
	
	var points = [
		Vector3(position.x - size.x/2, position.y + size.y/2, position.z + size.z/2),
		Vector3(position.x + size.x/2, position.y + size.y/2, position.z + size.z/2),
		Vector3(position.x + size.x/2, position.y + size.y/2, position.z - size.z/2),
		Vector3(position.x - size.x/2, position.y - size.y/2, position.z - size.z/2),
		Vector3(position.x + size.x/2, position.y - size.y/2, position.z - size.z/2),
		Vector3(position.x + size.x/2, position.y - size.y/2, position.z + size.z/2),
		Vector3(position.x - size.x/2, position.y + size.y/2, position.z + size.z/2),
		Vector3(position.x - size.x/2, position.y + size.y/2, position.z - size.z/2),
		Vector3(position.x - size.x/2, position.y - size.y/2, position.z - size.z/2),
		Vector3(position.x + size.x/2, position.y - size.y/2, position.z + size.z/2),
		Vector3(position.x + size.x/2, position.y - size.y/2, position.z - size.z/2),
		Vector3(position.x + size.x/2, position.y + size.y/2, position.z - size.z/2),
		Vector3(position.x + size.x/2, position.y + size.y/2, position.z + size.z/2),
		Vector3(position.x - size.x/2, position.y + size.y/2, position.z + size.z/2),
		Vector3(position.x - size.x/2, position.y - size.y/2, position.z + size.z/2),
		Vector3(position.x + size.x/2, position.y - size.y/2, position.z - size.z/2),
		Vector3(position.x - size.x/2, position.y - size.y/2, position.z - size.z/2),
		Vector3(position.x - size.x/2, position.y + size.y/2, position.z - size.z/2)
	]
	
	for index in points.size():
		var pos = points[index]
		var axes = surface_axes[surface]
		if pos[axes[0]] == target[axes[0]]:
			if pos[axes[1]] > position[axes[1]]:
				pos[axes[1]] -= indent
			else:
				pos[axes[1]] += indent
			if pos[axes[2]] > position[axes[2]]:
				pos[axes[2]] -= indent
			else:
				pos[axes[2]] += indent
		points[index] = SourceGD.Vertex.new(pos)
	
	self.sides = [
		SourceGD.Side.new(SourceGD.VPlane.new([ points[0], points[1], points[2] ]), materials[0], SourceGD.uvaxes.z),
		SourceGD.Side.new(SourceGD.VPlane.new([ points[3], points[4], points[5] ]), materials[1], SourceGD.uvaxes.z),
		SourceGD.Side.new(SourceGD.VPlane.new([ points[6], points[7], points[8] ]), materials[3], SourceGD.uvaxes.x),
		SourceGD.Side.new(SourceGD.VPlane.new([ points[9], points[10], points[11] ]), materials[2], SourceGD.uvaxes.x),
		SourceGD.Side.new(SourceGD.VPlane.new([ points[12], points[13], points[14] ]), materials[4], SourceGD.uvaxes.y),
		SourceGD.Side.new(SourceGD.VPlane.new([ points[15], points[16], points[17] ]), materials[5], SourceGD.uvaxes.y)
	]
