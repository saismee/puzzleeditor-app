extends Node

@onready var Ribbon = get_tree().root.get_node("Spatial/UI/Ribbon")

var regex: RegEx

func _ready() -> void:
	regex = RegEx.new()
	regex.compile(r"leaked!")

func _iterate_conditions(conditions: Array, values: Dictionary, out: Array) -> void:
	for index in conditions.size():
		var cond = conditions[index]
		match cond.type:
			"switch":
				if cond.results.has(str(values[cond.key])):
					_iterate_conditions(cond.results[str(values[cond.key])], values, out)
				else:
					_iterate_conditions(cond.results.default, values, out)
			_:
				out.append(cond)

func setup_directories() -> void:
	var game_config: Dictionary = Data.global_config.games[Data.game]
	if !DirAccess.dir_exists_absolute(game_config.path + "\\sdk_content\\maps\\puzedit"):
		DirAccess.make_dir_absolute(game_config.path + "\\sdk_content\\maps\\puzedit")
	if !DirAccess.dir_exists_absolute(game_config.path + "\\sdk_content\\maps\\instances\\puzedit"):
		DirAccess.make_dir_absolute(game_config.path + "\\sdk_content\\maps\\instances\\puzedit")
	
	if !DirAccess.dir_exists_absolute(game_config.path + "\\" + game_config.id + "\\maps\\puzedit"):
		DirAccess.make_dir_absolute(game_config.path + "\\" + game_config.id + "\\maps\\puzedit")

func export_vmf() -> String: # returns the VMF filepath
	setup_directories()
	Logger.info("Exporting project - Game: " + Data.game)
	var start_time: int = Time.get_ticks_usec()
	
	var vmf_name: String = "puzedit.vmf"#str(floor(Time.get_unix_time_from_system())) + ".vmf"
	
	var game_config: Dictionary = Data.global_config.games[Data.game]
	
	if Data.global_config.options.developer_mode == 0:
		Logger.info("Cloning instances from " + "//packages/instances to " + (game_config.path + "\\sdk_content\\maps\\instances\\puzedit") )
		var start_export_time: int = Time.get_ticks_usec()
		Util.copy_dir("res://packages/instances", game_config.path + "\\sdk_content\\maps\\instances\\puzedit")
		Logger.info("Time taken to clone instances: " + str((Time.get_ticks_usec() - start_export_time) * 1e-6) + " seconds")
	else:
		SPopup.new("Developer Mode", "Developer Mode is enabled, instances will not be cloned!\nTHIS WILL CAUSE A COMPILE FAILURE!")
		Logger.info("Skipping instance cloning - debug mode is active")
	
	var out: SourceGD.VMF = SourceGD.VMF.new()
	
	var empty_voxels: PackedVector3Array = PackedVector3Array()
	var brushes: Array[Dictionary] = [{}, {}, {}, {}, {}, {}]
	
	Logger.info("Adding entities...")
	for index: int in Data.entities.size():
		if Data.entities[index] == null: continue
		var entity: Entity = Data.entities[index]
		var entity_info: Dictionary = Data.registered_entities[entity.name]
		Logger.verbose("Adding entity: " + entity.name + " (" + str(index) + ")")
		
		var embedded_volumes: Array = Util.has(entity_info.export, "embedded_volumes", []) # array type?
		
		var instances: Array[Dictionary] = []
		_iterate_conditions(entity_info.export.conditions, entity.options, instances)
		
		for condindex: int in instances.size():
			var cond: Dictionary = instances[condindex]
			if cond.type == "add_instance":
				# creates an instance with connections
				#var rot: Vector3 = entity.export_rotation + entity.angle
				var basis: Basis = entity.surface.to_basis()
				var rot_out: Basis = basis.rotated(basis.x, entity.export_rotation.x).rotated(basis.y, entity.export_rotation.y).rotated(basis.z, entity.export_rotation.z)
				#var rot_out: Basis = basis.rotated(basis.x, entity.angle.x).rotated(basis.y, entity.angle.y).rotated(basis.z, entity.angle.z)
				rot_out = rot_out.rotated(rot_out.x, entity.angle.z).rotated(rot_out.y, entity.angle.y).rotated(rot_out.z, entity.angle.x)
				var rot_euler: Vector3 = rot_out.get_euler()
				
				var pos_basis: Basis = basis.rotated(basis.x, entity.export_rotation.x).rotated(basis.y, entity.export_rotation.y).rotated(basis.z, entity.export_rotation.z)
				var pos: Vector3 = Vector3.ZERO
				if cond.has("global_position"):
					pos = Util.parse_vector(cond.global_position) * 128
					rot_euler = Vector3.ZERO
				else:
					pos = (entity.position + Util.translate_relative(pos_basis, entity_info.editor.size/2) + Util.has(cond, "position", Vector3.ZERO)) * 128
				
				var v_entity: SourceGD.VEntity = SourceGD.VEntity.new(
					"func_instance",
					pos,
					Vector3(rot_euler.x, rot_euler.z, rot_euler.y) / (PI/180)
				)
				
				v_entity["file"] = "instances/puzedit/" + cond.instance + ".vmf"
				v_entity["targetname"] = entity.name + "_" + str(index)
				
				for con: int in entity.connections.outputs.size():
					var output: Dictionary = entity.connections.outputs[con]
					var target: Entity = Data.entities[output.target]
					var target_info: Dictionary = Data.registered_entities[target.name]
					
					var input: Dictionary
					for con2: int in target.connections.inputs.size():
						if target.connections.inputs[con2].id == output.id:
							input = target.connections.inputs[con2]
							break
					
					if (!target_info.export.connections.inputs[input.type].has("invert_var")) or (!target.options[target_info.export.connections.inputs[input.type].invert_var]):
						v_entity.add_output(
							entity_info.export.connections.outputs[output.type].activate.replace(",", ""),
							target.name + "_" + str(output.target) + "" + target_info.export.connections.inputs[input.type].activate.replace(",", "")
						)
						v_entity.add_output(
							entity_info.export.connections.outputs[output.type].deactivate.replace(",", ""),
							target.name + "_" + str(output.target) + "" + target_info.export.connections.inputs[input.type].deactivate.replace(",", "")
						)
					else:
						# flip the activate and deactivate values
						v_entity.add_output(
							entity_info.export.connections.outputs[output.type].activate.replace(",", ""),
							target.name + "_" + str(output.target) + "" + target_info.export.connections.inputs[input.type].deactivate.replace(",", "")
						)
						v_entity.add_output(
							entity_info.export.connections.outputs[output.type].deactivate.replace(",", ""),
							target.name + "_" + str(output.target) + "" + target_info.export.connections.inputs[input.type].activate.replace(",", "")
						)
						
				
				v_entity["replace01"] = "$connectioncount " + str(entity.connections.inputs.size())
				
				if cond.has("fixups"):
					var fixup_count: int = 2
					for fixup: String in cond.fixups:
						if cond.fixups[fixup] is String:
							#fixup directly points to an option's value - pass that
							v_entity["replace0" + str(fixup_count)] = str(fixup) + " " + str(entity.options[cond.fixups[fixup]])
							fixup_count += 1
						elif cond.fixups[fixup] is Dictionary:
							# fixup is a mapping of values - pass in the current value and get the result
							v_entity["replace0" + str(fixup_count)] = str(fixup) + " " + str(cond.fixups[fixup].results[str(entity.options[cond.fixups[fixup].key])])
							fixup_count += 1
				
				out.add(v_entity) # append the entity to the VMF
			elif cond.type == "add_overlay":
				# creates an instance WITHOUT connections
				# somewhat deprecated
				var v_entity: SourceGD.VEntity = SourceGD.VEntity.new("func_instance", (entity.position + Util.translate_relative(Util.surface_orientations[entity.surface], entity_info.editor.size)/2) * 128, Util.export_orientations[entity.surface].get_euler() / (PI/180))
				v_entity["file"] = "instances/puzedit/" + cond.instance + ".vmf"
				out.add(v_entity) # append the entity to the VMF
			elif cond.type == "embed_volume":
				# special case, this is handled by the geometry stuff
				embedded_volumes.append({
					start = cond.start,
					end = cond.end
				})
		
		for volume: Dictionary in embedded_volumes:
			var a: Vector3 = Util.parse_vector(volume.start) / Data.grid_size
			var b: Vector3 = Util.parse_vector(volume.end) / Data.grid_size
			
			for x: int in range( min(a.x, b.x), max(a.x, b.x) ):
				for y: int in range( min(a.y, b.y), max(a.y, b.y) ):
					for z: int in range( min(a.z, b.z), max(a.z, b.z) ):
						empty_voxels.append(Vector3i(round((entity.position + Util.export_offsets[entity.surface.value]*Data.grid_size + Util.translate_relative(entity.surface.to_basis(), (Vector3(x, y, z) + Util.embed_offsets[entity.surface.value])*Data.grid_size)) * 128)))
	
	Logger.info("Generating geometry...")
#	var generated = PackedVector3Array()
#	var generated = {}
	
	for index: Vector3 in Data.voxels:
		var voxel: Voxel = Data.voxels[Vector3i(index)] # make voxel class?
		Logger.verbose("Adding voxel: " + str(index))
		
		for surf_index: int in 6:
			var surface: Surface = Surface.new(surf_index)
			var new_index: Vector3 = index + Util.surface_normals[surface.value]
			if Data.voxels.has(Vector3i(new_index)): continue
			
			var perp_surf: Vector3 = Util.perpendicular_vector(surface.normal) / Data.grid_size
			for x: int in range( max(perp_surf.x, 1) ):
				for y: int in range( max(perp_surf.y, 1) ):
					for z: int in range( max(perp_surf.z, 1) ):
						var pos: Vector3i = Vector3i(round((new_index + Vector3(x, y, z)*Data.grid_size) * 128))
						
						# hardcoded but i dont see a way around it
						if surf_index == 0:
							pos += Vector3i(0, round((1-Data.grid_size) * 128), 0)
						elif surf_index == 2:
							pos += Vector3i(0, 0, round((1-Data.grid_size) * 128))
						elif surf_index == 4:
							pos += Vector3i(round((1-Data.grid_size) * 128), 0, 0)
						
						if !brushes[surf_index].has(pos) and !empty_voxels.has(pos):
							brushes[surf_index][pos] = {
								material = Data.registered_skins[Data.skin].registered_materials[voxel.surfaces[surf_index].material].export_material
							}
	
	Logger.info("Simplifying geometry...")
	
	var exported: Array[Dictionary] = [{}, {}, {}, {}, {}, {}]
	
	for surf_index: int in brushes.size():
		for brush_index: Vector3i in brushes[surf_index]:
			var surface: Surface = Surface.new(surf_index)
			
			if exported[surf_index].has(Vector3i(brush_index)): continue
			var brush: Dictionary = brushes[surf_index][brush_index]
			var to_combine: Array[Vector3i] = [Vector3i(brush_index)]
			
			var gs: int = round(128 * Data.grid_size)
			
			var start: Vector3i = Vector3i(brush_index)
			var end: Vector3i = Vector3i(brush_index)
			
			var exit: bool = false
			
			# the following code took me multiple days to write and rewrite.
			# i hate it, i never want to look at it again
			# i know theres a better way, but this works and i dont give a fuck anymore
			while brushes[surf_index].has(end + Vector3i(gs, 0, 0)):
				end += Vector3i(gs, 0, 0)
				if (brushes[surf_index][end] != brush) or (exported[surf_index].has(end)):
					end -= Vector3i(gs, 0, 0)
					break
			
			while brushes[surf_index].has(end + Vector3i(0, gs, 0)):
				end += Vector3i(0, gs, 0)
				for x in range(start.x, end.x + gs, gs):
					if (!brushes[surf_index].has(Vector3i(x, end.y, end.z))) or (brushes[surf_index][Vector3i(x, end.y, end.z)] != brush) or (exported[surf_index].has(Vector3i(x, end.y, end.z))):
						end -= Vector3i(0, gs, 0)
						exit = true
						break
				if exit: break
			
			exit = false
			
			while brushes[surf_index].has(end + Vector3i(0, 0, gs)):
				end += Vector3i(0, 0, gs)
				for x in range(start.x, end.x + gs, gs):
					for y in range(start.y, end.y + gs, gs):
						if (!brushes[surf_index].has(Vector3i(x, y, end.z))) or (brushes[surf_index][Vector3i(x, y, end.z)] != brush) or (exported[surf_index].has(Vector3i(x, y, end.z))):
							end -= Vector3i(0, 0, gs)
							exit = true
							break
					if exit: break
				if exit: break
			#asdjhkgvjheklewkfkljrweklgjrfkljcvolpikergolikerfiklgierbnikolnwkjgtbkjl
			
			for x: int in range(start.x, end.x + gs, gs):
				for y: int in range(start.y, end.y + gs, gs):
					for z: int in range(start.z, end.z + gs, gs):
						exported[surf_index][Vector3i(x, y, z)] = true
			
			var materials: Array[String] = [ # material class?
				"TOOLS/TOOLSNODRAW",
				"TOOLS/TOOLSNODRAW",
				"TOOLS/TOOLSNODRAW",
				"TOOLS/TOOLSNODRAW",
				"TOOLS/TOOLSNODRAW",
				"TOOLS/TOOLSNODRAW"
			]
			
			materials[surf_index] = brush.material
			
	#		Logger.info(str(start) + str(end))
			
			var adjacent: Array[bool] = [
				brushes[surf_index].has(end + Vector3i(Util.surface_adjacents[surf_index].x) * gs),
				brushes[surf_index].has(start - Vector3i(Util.surface_adjacents[surf_index].x) * gs),
				brushes[surf_index].has(end + Vector3i(Util.surface_adjacents[surf_index].z) * gs),
				brushes[surf_index].has(start - Vector3i(Util.surface_adjacents[surf_index].z) * gs)
			]
			
			
			
			var v_solid: SurfaceSolid = SurfaceSolid.new(
				Vector3i(start.x + end.x, start.y + end.y, start.z + end.z)/2 + Vector3i(gs, gs, gs)/2 - Vector3i(Util.surface_normals[surface.value] * gs * 0.375),
				Vector3i(end.z - start.z, end.y - start.y, end.x - start.x).abs() + Vector3i(gs, gs, gs) - Vector3i(Util.export_normals[surface.value].abs() * gs * 0.75),
				materials, surface.value, [true, true, true, true], gs/4
			)
			
			out.add(v_solid)
	
	Logger.info("Time taken to pre-compile: " + str((Time.get_ticks_usec() - start_time) * 1e-6) + " seconds")
	
	Logger.info("Writing VMF...")
	var file = FileAccess.open(game_config.path + "\\sdk_content\\maps\\puzedit\\" + vmf_name, FileAccess.WRITE)
	# TODO: find the actual portal install location - this likely wont be valid
	file.store_string(out.collapse())
	file.close()
	
	Logger.info("Exported to sdk_content/maps/puzedit/" + vmf_name)
	return "\\sdk_content\\maps\\puzedit\\" + vmf_name

func compile_vmf(filepath: String) -> bool:
	var os: String = OS.get_name()
	if os != "Windows" and os != "UWP":
		Logger.warn("Unsupported OS: " + os)
		SPopup.new("Unsupported OS", "PuzEdit does not support compiling on your operating system, try exporting as VMF.\nYou are using: " + os + ".\nPuzEdit supports: Windows")
		return false
	
	var game_config: Dictionary = Data.global_config.games[Data.game]
	var cmd_out: Array = []
	
	var export_config: Dictionary = game_config.duplicate()
	export_config.map_name = filepath.replace("\\", "/")
	for compilername in export_config.compilers:
		export_config[compilername] = export_config.compilers[compilername]
	
	#OS.execute("CMD.exe", ["/C", 'start "" "' + ProjectSettings.globalize_path("user://compile/" + Data.game.replace(" ", "-") + "_full_windows.bat") + '"'], cmd_out, true, true)
	#Logger.info('&& "{vbsp}" -leaktest -game "{path}/{id}" "{path}{map_name}"'.format(export_config))
	#Logger.info(
		#[
		#"/C",
		#'cd "{path}/bin"'.format(export_config),
		#'&& "{vbsp}" -leaktest -game "{path}/{id}" "{path}{map_name}"'.format(export_config),
		#'&& "{vvis}" -game "{path}/{id}" "{path}{map_name}"'.format(export_config),
		#'&& "{vrad}" -hdr -final -textureshadows -StaticPropLighting -StaticPropPolys -game "{path}\\{id}" "{path}{map_name}"'.format(export_config),
		#'&& pause'
	#]
	#)
	var exit_code: int = OS.execute("CMD.exe", [
		('/C'
		+ ' cd "{path}/bin"'
		+ ' && "{vbsp}" -leaktest -game "{path}/{id}" "{path}{map_name}"'
		+ ' && "{vvis}" -game "{path}/{id}" "{path}{map_name}"'
		+ ' && "{vrad}" -hdr -final -textureshadows -StaticPropLighting -StaticPropPolys -game "{path}/{id}" "{path}{map_name}"').format(export_config)
	], cmd_out, true, true)
	DirAccess.copy_absolute(game_config.path + filepath.trim_suffix(".vmf") + ".bsp", game_config.path + "/" + game_config.id + "/maps/puzedit.bsp")
	
	if exit_code == 1:
		# oh no
		Logger.warn("Build failed with code 1")
		SPopup.new("Build Error", "Build failed with code 1. See console for more details.")
		for out: String in cmd_out:
			Logger.info(out)
			var result: RegExMatch = regex.search(out)
			if result and result.strings.size() > 0:
				load_pointfile(filepath)
				# we have a leak! load the pointfile (.lin)
		return false
	for out: String in cmd_out:
		Logger.info(out)
	
	return true

var pointfile_count: int = 0

func load_pointfile(filepath: String) -> void:
	unload_pointfile()
	
	var splitpath: PackedStringArray = filepath.split(".")
	var path: String = Data.global_config.games[Data.game].path + splitpath[0] + ".lin"
	if FileAccess.file_exists(path):
		pointfile_count = 0
		Ribbon.set_item_enabled("Hide Build Error", true)
		SPopup.new("Leak Detected", "An entity is in an invalid location, causing a build error.\nA red line has been added to indicate the location of the error.\nYou can hide this with File > Hide Build Error.")
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		var vectors: Array[Vector3] = []
		
		for vector: String in file.get_as_text().split("\n", false):
			vectors.append(Util.parse_vector(vector.strip_escapes(), " "))
		for index: int in vectors.size()-1:
			pointfile_count += 1
			var mesh: Mesh = Debug.add_line("pointfile_" + str(index), Vector3(vectors[index].y, vectors[index].z, vectors[index].x)/128, Vector3(vectors[index + 1].y, vectors[index + 1].z, vectors[index + 1].x)/128)
			mesh.material = ContentLoader._load("res://materials/error.tres")

func unload_pointfile() -> void:
	Ribbon.set_item_enabled("Hide Build Error", false)
	for index: int in pointfile_count:
		Debug.remove_line("pointfile_" + str(index))

func open_map(filepath: String) -> void:
	var os := OS.get_name()
	if os != "Windows" and os != "UWP":
		Logger.warn("Unsupported OS: " + os)
		SPopup.new("Unsupported OS", "PuzEdit does not support playing on your operating system, try exporting as VMF.\nYou are using: " + os + ".\nPuzEdit supports: Windows")
		return
	
	var game_config: Dictionary = Data.global_config.games[Data.game]
	var cmd_out: Array = []
	
	var export_config: Dictionary = game_config.duplicate()
	export_config.map_name = filepath.replace("\\", "/")
	for compilername in export_config.compilers:
		export_config[compilername] = export_config.compilers[compilername]
	
	Logger.info('"{executable}"'.format(export_config))
	Logger.info(['-dev -novid -game "{path}\\{id} +map {mapname} +sv_lan 1"'.format(export_config)])
	OS.create_process('{executable}'.format(export_config), ['-dev', '-novid', '-game "{path}/{id}"'.format(export_config), '+map puzedit', '+sv_lan 1'])
	
	#OS.create_process("CMD.exe", ["/C", 'start "" "' + ProjectSettings.globalize_path("user://compile/" + Data.game.replace(" ", "-") + "_exec_windows.bat") + '" ' + filepath])

func puzzlemaker_export() -> void:
	var map_name: String = export_vmf()
	SPopup.new("Export Result", "Successfully exported map to " + Data.global_config.games[Data.game].path + map_name)

func puzzlemaker_build() -> void:
	var map_name: String = export_vmf()
	if compile_vmf(map_name):
		SPopup.new("Export Result", "Successfully compiled map to " + Data.global_config.games[Data.game].path + "/" + Data.global_config.games[Data.game].id + "/maps/puzedit.bsp")

func puzzlemaker_build_and_run() -> void:
	var map_name: String = export_vmf()
	if compile_vmf(map_name):
		open_map(map_name)
