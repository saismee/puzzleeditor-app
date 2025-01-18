class_name Entity

var name: String
var connections: Dictionary
var options: Dictionary
var handles: Dictionary

var position: Vector3 : set = _set_position
var rotation: Vector3 : set = _set_rotation
var export_rotation: Vector3 : set = _set_export_rotation # doesnt rotate the entity, only rotates the meshes!
var angle: Vector3 : set = _set_angle
var surface: Surface

var object: MeshInstance3D : set = _set_object
var handle_object: Node : set = _set_handle_object
var meshes: Array

func fixup(text: String, values: Dictionary):
	for key in values:
		text = text.replace("$" + key, str(values[key]))
	return text

func _init(name: String, pos: Vector3 = Vector3.ZERO, surface: Surface = Surface.new(), rot: Vector3 = Vector3.ZERO) -> void:
	if !Data.registered_entities.has(name):
		Logger.warn(name + " is missing!")
		SPopup.new("Entity missing", name + " is missing!\nDid you remove a package?", "Ignore")
		return
	
	self.name = name
	self.connections = {
		inputs = [],
		outputs = []
	}
	self.options = Util.has(Data.registered_entities[name].editor, "options", {}).duplicate(true)
	
	self.handles = Util.has(Data.registered_entities[name].editor, "handles", {}).duplicate(true)
	
	self.position = pos
	self.rotation = rot
	self.export_rotation = Vector3.ZERO
	self.surface = surface
	
	self.meshes = []

func _set_object(obj: MeshInstance3D) -> void:
	object = obj
	_update_object()

func _set_handle_object(obj: Node) -> void:
	handle_object = obj
	var handle_list = Data.registered_entities[name].editor.handles
	
	for handle_name: String in handle_list:
		var mesh = Util.has(handle_list[handle_name], "mesh", ContentLoader._load("res://meshes/missing.obj"))
		
		var node := MeshInstance3D.new()
		node.mesh = mesh
		node.name = handle_name
		#node.position = handle_list[handle_name].positions[self.handles[handle_name]]
		node.create_convex_collision(false, false)
		
		#node.add_to_group("handle")
		node.set_meta("entity", object.name.to_int())
		
		handle_object.add_child(node)
		set_handle(handle_name, self.handles[handle_name])
	

func _update_object() -> void:
	if self.object != null:
		#Logger.info(self.rotation + self.export_rotation)
		self.object.rotation = self.rotation * (PI/180)
		self.object.rotate_object_local(Vector3.FORWARD, self.export_rotation.x + self.angle.x)
		self.object.rotate_object_local(Vector3.UP, self.export_rotation.y + self.angle.y)
		self.object.rotate_object_local(Vector3.RIGHT, self.export_rotation.z + self.angle.z)
		
		var basis: Basis = self.surface.to_basis()
		
		self.object.position = self.position + Util.translate_relative(
			basis
			.rotated(basis.x, self.export_rotation.x)
			.rotated(basis.y, self.export_rotation.y)
			.rotated(basis.z, self.export_rotation.z),
			Data.registered_entities[name].editor.size
		)/2# - Util.surface_normals[self.surface]/2
		
		if self.handle_object:
			self.handle_object.position = self.position + Util.translate_relative(
				basis,
				Data.registered_entities[name].editor.size
			)/2
			self.handle_object.rotation = self.rotation * (PI/180)
			self.handle_object.rotate_object_local(Vector3.FORWARD, self.angle.x)
			self.handle_object.rotate_object_local(Vector3.UP, self.angle.y)
			self.handle_object.rotate_object_local(Vector3.RIGHT, self.angle.z)
			#for handle: Node in self.handle_object.get_children():
				#handle.rotation = self.object.rotation
		
		#self.object.get_node("handles").global_position = self.position + Data.registered_entities[name].editor.size/2
	#for node in self.meshes:
		#node.rotation = self.export_rotation

func set_handle(handle: String, value: Variant) -> void:
	var handle_info: Dictionary = Data.registered_entities[name].editor.handles[handle]
	
	self.handles[handle] = value
	self.handle_object.get_node(handle).position = handle_info.positions[value]
	update_mesh()
	
	if handle_info.type == "rotation_90_deg":
		export_rotation = Vector3(0, (value + 1) * 90 * (PI/180), 0)

func unlink_connection(connection_id: int) -> bool:
	for index in connections.outputs.size():
		if connections.outputs[index].id != connection_id: continue
		connections.outputs.remove_at(index)
		return true
	for index in connections.inputs.size():
		if connections.inputs[index].id != connection_id: continue
		connections.inputs.remove_at(index)
		return true
	return false

func select() -> void:
	for node in self.meshes:
		node.material_override = ContentLoader._load("res://materials/depthsel.tres")
	if !self.object: return
	self.handle_object.visible = true
	for handle: MeshInstance3D in handle_object.get_children():
		handle.get_child(0).collision_layer = 1

func deselect() -> void:
	for node in self.meshes:
		node.material_override = null
	if !self.object: return
	self.handle_object.visible = false
	for handle: MeshInstance3D in handle_object.get_children():
		handle.get_child(0).collision_layer = 0

func _get_mirror_position() -> Vector3:
	var occupied_voxel: Vector3i = position
	var normal: Vector3i = self.surface.normal
	var offset: Vector3i = Vector3i(normal)
	
	while Data.voxels.has(occupied_voxel - offset):
		offset += normal
	return Vector3(0, offset.length() - Data.registered_entities[name].editor.size.y, 0)

func update_mesh() -> void:
	if !self.object: return
	var out = []
	var condition_options: Dictionary = {}
	if Data.registered_entities[name].editor.has("conditions"):
		
		condition_options = self.options.duplicate() # create new dictionary
		condition_options.merge(self.handles)
		# merge all condition-related options in
		# this allows conditions to use switch cases to change mesh, etc
		condition_options.mirror_position = _get_mirror_position()
		
		iterate_conditions(Data.registered_entities[name].editor.conditions, condition_options, out)
	else:
		out = [{
			"type": "set_mesh",
			"mesh": Util.has(Data.registered_entities[name].editor, "mesh", ContentLoader._load("res://meshes/missing.obj"))
		}]
	
	for node in self.meshes:
		self.object.remove_child(node)
		node.queue_free()
	self.meshes = [
		MeshInstance3D.new()
	]
	_delete_collisions()
	
	for cond in out:
		match cond.type:
			"set_mesh":
				self.meshes[0].mesh = cond.mesh
				
				self.object.mesh = cond.mesh
				self.object.create_convex_collision(false, false)
				self.object.mesh = null
			"add_mesh":
				var mesh = MeshInstance3D.new()
				mesh.mesh = cond.mesh
				if Util.has(cond, "mirrored", false):
					var mesh_position: Vector3 = Util.parse_vector(fixup(cond.position, condition_options))
					
					mesh.position = mesh_position + Vector3(condition_options.mirror_position)
					mesh.rotation = Vector3(0, 0, PI)
				else:
					mesh.position = Util.parse_vector(fixup(cond.position, condition_options))
				meshes.append(mesh)
			"add_stretched_mesh":
				var mesh = MeshInstance3D.new()
				mesh.mesh = cond.mesh
				
				var end_position: Vector3 = Util.parse_vector(fixup(cond.end_position, condition_options))
				var mesh_position: Vector3 = Util.parse_vector(fixup(cond.position, condition_options))
				mesh.position = (mesh_position + end_position) / 2
				var scale: Vector3 = mesh_position - end_position
				mesh.scale = Vector3(
					1 if scale.x == 0 else scale.x - 0.25,
					1 if scale.y == 0 else scale.y - 0.25,
					1 if scale.z == 0 else scale.z - 0.25
				)
				Logger.info(mesh_position - end_position)
				meshes.append(mesh)
			"shift_mesh":
				for node: MeshInstance3D in meshes:
					node.position += Util.parse_vector(fixup(cond.position, condition_options))
			"rotate":
				angle = Util.parse_vector(fixup(cond.rotation, condition_options)) * (PI/180)
	
	for node in self.meshes:
		self.object.add_child(node)

func _delete_collisions() -> void:
	for child in self.object.get_children():
		if !(child is CollisionObject3D): continue
		self.object.remove_child(child)
		child.queue_free()

func _set_position(pos: Vector3) -> void:
	position = pos
	_update_object()
	update_mesh()

func _set_rotation(rot: Vector3) -> void:
	rotation = rot
	_update_object()

func _set_export_rotation(rot: Vector3) -> void:
	export_rotation = rot
	_update_object()

func _set_angle(rot: Vector3) -> void:
	angle = rot
	_update_object()

func iterate_conditions(conditions: Array, values: Dictionary, out: Array) -> void:
	for index in conditions.size():
		var cond = conditions[index]
		match cond.type:
			"switch":
				if cond.results.has(str(values[cond.key])):
					iterate_conditions(cond.results[str(values[cond.key])], values, out)
				else:
					iterate_conditions(cond.results.default, values, out)
			_:
				out.append(cond)

func _to_string() -> String:
	return JSON.stringify({
		name = self.name,
		connections = self.connections,
		options = self.options,
		handles = self.handles,
		position = self.position,
		rotation = self.rotation,
		surface = self.surface.value
	})
