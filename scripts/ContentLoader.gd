extends Node

var assets = {}

func generate_default_directories() -> void:
	DirAccess.make_dir_absolute("user://packages")
	DirAccess.make_dir_absolute("user://packages/skin")
	DirAccess.make_dir_absolute("user://packages/entity")

func _load(resource):
	if resource.substr(0, 11) == "packages://":
		resource = "user://packages/" + resource.substr(11)
		# TODO: completely redo user mesh imports
	if !assets.has(resource):
		Logger.info("Loading Asset: " + resource)
		assets[resource] = load(resource)
	return assets[resource]

func _unload(resource):
	if assets.has(resource):
		Logger.info("Unloading Asset: " + resource)
		assets.erase(resource)

func _unload_all():
	for resource in assets:
		_unload(resource)

func __load(array):
	if typeof(array) == TYPE_DICTIONARY:
		for index in array:
			array[index] = __load(array[index])
	elif typeof(array) == TYPE_ARRAY:
		for index in array.size():
			array[index] = __load(array[index])
	elif (typeof(array) == TYPE_STRING) and ((array.substr(0, 6) == "res://") or (array.substr(0, 11) == "packages://")):
		#_unload(array)
		return _load(array)
	return array

func _loadjson(resource):
	_unload(resource)
	var res = load(resource)
	if res == null:
		Logger.error("Failed to parse json for " + resource)
		return
	assets[resource] = res.data
	return res.data

func _loadspecial(type: String, resource: String) -> Variant:
	var dir = "res://packages/" + type + "/" + resource
	if DirAccess.dir_exists_absolute("user://packages/" + type) and DirAccess.dir_exists_absolute("user://packages/" + type + "/" + resource):
		dir = "user://packages/" + type + "/" + resource
	
	if type == "skin":
		var skin = _loadjson(dir + "/info.json")
		
		if skin == null: return null
		return EditorSkin.new(dir, __load(skin))
	elif type == "entity":
		var entity = _loadjson(dir + "/info.json")
		if entity == null: return null
		
		entity.editor = Util.has(entity, "editor", {})
		entity.editor.options = Util.has(entity.editor, "options", {})
		entity.editor.locked = Util.has(entity.editor, "locked", false)
		
		entity.editor.handles = Util.has(entity.editor, "handles", {})
		for handle in entity.editor.handles:
			for pos_index in Util.has(entity.editor.handles[handle], "positions", []).size():
				entity.editor.handles[handle].positions[pos_index] = Util.parse_vector(entity.editor.handles[handle].positions[pos_index])
		
		entity.editor.size = Util.parse_vector(Util.has(entity.editor, "size", "(0.25,0.25,0.25)"))
		entity.editor.offset = Util.parse_vector(Util.has(entity.editor, "offset", "(0,0,0)"))
		
		entity.export = Util.has(entity, "export", {})
		entity.export.embedded_voxels = Util.has(entity.export, "embedded_voxels", [])
		entity.export.conditions = Util.has(entity.export, "conditions", [])
		return __load(entity)
	return null
