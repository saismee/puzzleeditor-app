class_name SurfaceSolid extends SourceGD.BaseSolid

var surface_axes = [
	["y", "x", "z"], # 0
	["y", "x", "z"], # 1
	["x", "y", "z"], # 2
	["x", "y", "z"], # 3
	["z", "x", "y"], # 4
	["z", "x", "y"]  # 5
]

var surface_indents = [
	["z", "x"], # 0
	["z", "x"], # 1
	["z", "y"], # 2
	["z", "y"], # 3
	["x", "y"], # 4
	["x", "y"], # 5
]

var surface_orientations = [
	Basis(Vector3(0,1,0),0) * Basis(Vector3(0,1,0),PI/2),
	Basis(Vector3(1,0,0),PI) * Basis(Vector3(0,1,0),PI/2),
	Basis(Vector3(1,0,0),PI/2) * Basis(Vector3(0,1,0),PI),
	Basis(Vector3(1,0,0),PI*1.5),
	Basis(Vector3(0,0,1),PI*1.5) * Basis(Vector3(0,1,0),-PI/2),
	Basis(Vector3(0,0,1),PI/2) * Basis(Vector3(0,1,0),PI/2),
]

func get_axis(vec: Vector3) -> String:
	if vec.x > 0: return "x"
	elif vec.y > 0: return "y"
	else: return "z"

func _init(position: Vector3i, size: Vector3i, materials: Array, surface: int, adjacent: Array, indent: int = 8) -> void:
	position = Vector3i(position.z, position.y, position.x)
	
	var target = position
	
	if surface % 2 == 1:
		target = position + Vector3i(size.x/2, size.y/2, size.z/2)
	else:
		target = position - Vector3i(size.x/2, size.y/2, size.z/2)
	
	var points = [ # PackedVector3Array maybe?
		Vector3i(position.x - size.x/2, position.y + size.y/2, position.z + size.z/2),
		Vector3i(position.x + size.x/2, position.y + size.y/2, position.z + size.z/2),
		Vector3i(position.x + size.x/2, position.y + size.y/2, position.z - size.z/2),
		Vector3i(position.x - size.x/2, position.y - size.y/2, position.z - size.z/2),
		Vector3i(position.x + size.x/2, position.y - size.y/2, position.z - size.z/2),
		Vector3i(position.x + size.x/2, position.y - size.y/2, position.z + size.z/2),
		Vector3i(position.x - size.x/2, position.y + size.y/2, position.z + size.z/2),
		Vector3i(position.x - size.x/2, position.y + size.y/2, position.z - size.z/2),
		Vector3i(position.x - size.x/2, position.y - size.y/2, position.z - size.z/2),
		Vector3i(position.x + size.x/2, position.y - size.y/2, position.z + size.z/2),
		Vector3i(position.x + size.x/2, position.y - size.y/2, position.z - size.z/2),
		Vector3i(position.x + size.x/2, position.y + size.y/2, position.z - size.z/2),
		Vector3i(position.x + size.x/2, position.y + size.y/2, position.z + size.z/2),
		Vector3i(position.x - size.x/2, position.y + size.y/2, position.z + size.z/2),
		Vector3i(position.x - size.x/2, position.y - size.y/2, position.z + size.z/2),
		Vector3i(position.x + size.x/2, position.y - size.y/2, position.z - size.z/2),
		Vector3i(position.x - size.x/2, position.y - size.y/2, position.z - size.z/2),
		Vector3i(position.x - size.x/2, position.y + size.y/2, position.z - size.z/2)
	]
	
#	for index in points.size():
#		var pos = points[index]
#		var axes = surface_axes[surface]
#		if pos[axes[0]] == target[axes[0]]:
#
#			if pos[axes[1]] > position[axes[1]]:
#				pos[axes[1]] -= indent
#			else:
#				pos[axes[1]] += indent
#
#			if pos[axes[2]] > position[axes[2]]:
#				pos[axes[2]] -= indent
#			else:
#				pos[axes[2]] += indent
#
#		points[index] = SourceGD.Vertex.new(pos)
	
	var orientation = surface_orientations[surface]
	var axes = surface_axes[surface]
#	var xaxis = get_axis(orientation.x)
#	var yaxis = get_axis(orientation.z)
	var xaxis = surface_indents[surface][0]
	var yaxis = surface_indents[surface][1]
#	if xaxis == yaxis:
#		Logger.info([orientation, xaxis, yaxis, surface])
#		Logger.info([Vector3i(orientation.x), Vector3i(orientation.y), Vector3i(orientation.z)])
#		Logger.info([get_axis(Vector3i(orientation.x)), get_axis(Vector3i(orientation.z))])
#	if surface == 3 or surface == 4:
#	Logger.info([surface, xaxis, yaxis])
	for index in points.size():
		var pos = points[index]
#		if pos[axes[0]] == target[axes[0]]:
#			if pos[axes[1]] > position[axes[1]] and not adjacent[2]:
#				pos[axes[1]] -= indent
#			elif pos[axes[1]] < position[axes[1]] and not adjacent[3]:
#				pos[axes[1]] += indent
#
#			if pos[axes[2]] > position[axes[2]] and not adjacent[0]:
#				pos[axes[2]] -= indent
#			elif pos[axes[2]] < position[axes[2]] and not adjacent[1]:
#				pos[axes[2]] += indent
		if pos[axes[0]] == target[axes[0]]:
#			if surface == 3 or surface == 4:
#				Logger.info([xaxis, yaxis])
#				Logger.info(surface_axes[surface])
#				Logger.info([
#					pos[xaxis] == position[xaxis] + size[xaxis]/2 and adjacent[0],
#					pos[xaxis] == position[xaxis] - size[xaxis]/2 and adjacent[1],
#					pos[yaxis] == position[yaxis] + size[yaxis]/2 and adjacent[2],
#					pos[yaxis] == position[yaxis] - size[yaxis]/2 and adjacent[3]])
			
			if pos[xaxis] == position[xaxis] + size[xaxis]/2 and adjacent[0]:
				pos[xaxis] -= indent

			if pos[xaxis] == position[xaxis] - size[xaxis]/2 and adjacent[1]:
				pos[xaxis] += indent

			if pos[yaxis] == position[yaxis] + size[yaxis]/2 and adjacent[2]:
				pos[yaxis] -= indent

			if pos[yaxis] == position[yaxis] - size[yaxis]/2 and adjacent[3]:
				pos[yaxis] += indent
		
		points[index] = SourceGD.Vertex.new(pos)
	
	self.sides = [
		SourceGD.Side.new(SourceGD.VPlane.new([ points[0], points[1], points[2] ]), materials[0], SourceGD.uvaxes.z),
		SourceGD.Side.new(SourceGD.VPlane.new([ points[3], points[4], points[5] ]), materials[1], SourceGD.uvaxes.z),
		SourceGD.Side.new(SourceGD.VPlane.new([ points[6], points[7], points[8] ]), materials[3], SourceGD.uvaxes.x),
		SourceGD.Side.new(SourceGD.VPlane.new([ points[9], points[10], points[11] ]), materials[2], SourceGD.uvaxes.x),
		SourceGD.Side.new(SourceGD.VPlane.new([ points[12], points[13], points[14] ]), materials[4], SourceGD.uvaxes.y),
		SourceGD.Side.new(SourceGD.VPlane.new([ points[15], points[16], points[17] ]), materials[5], SourceGD.uvaxes.y)
	]
