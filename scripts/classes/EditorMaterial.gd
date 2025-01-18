class_name EditorMaterial

var editor_material: StandardMaterial3D
var export_material: String
var id: String

func _init(id: String, info: Dictionary) -> void:
	self.editor_material = StandardMaterial3D.new()
	self.editor_material.albedo_texture = info.editor
	self.export_material = info.export.to_upper()
	self.id = id

func _to_string() -> String:
	return "EditorMaterial(" + id + ")"
