class_name SFileDialog extends Node

var popup: FileDialog

func _init(type: FileType, function: Callable, parent: Node, file_mode: int = FileDialog.FILE_MODE_OPEN_FILE, access: int = FileDialog.ACCESS_USERDATA) -> void:
	var file = FileDialog.new()
	file.set_visible(true)
	file.position = Vector2i(parent.get_viewport().size.x / 2 - 400, parent.get_viewport().size.y / 2 - 300)
	file.size = Vector2i(800, 600)
	file.file_mode = file_mode
	file.set_filters(PackedStringArray([type.file_type]))
	file.access = access
	file.visible = true
	
	file.file_selected.connect(function)
	
	file.theme = ContentLoader._load("res://themes/perpetual/perpetual_dialog.tres")
	self.popup = file
	
	parent.add_child(file)
