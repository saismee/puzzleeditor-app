class_name EditorSkin

var name: String
var materials: Dictionary
var registered_materials: Dictionary
var editor_version: int

func _init(path: String, info: Dictionary) -> void:
	self.name = info.name
	self.registered_materials = {}
	self.materials = info.materials
	self.editor_version = Util.has(info, "editor_version", 0)
	
	for group_index in info.materials:
		for surface in info.materials[group_index]:
			for material in info.materials[group_index][surface]:
				var mat_info = ContentLoader.__load(ContentLoader._loadjson(path + "/materials/" + material + ".json"))
				self.registered_materials[material] = EditorMaterial.new(material, mat_info)
				self.materials[group_index][surface][material] = material

func _to_string() -> String:
	return "EditorSkin(" + self.name + ")"
