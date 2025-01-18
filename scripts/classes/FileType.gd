class_name FileType

const file_types = {
	EDITOR_FILES = "*.se; Editor Files",
	GAME_EXECUTABLES = "*.exe, *.bat; Game Executable Files"
}

var file_type: String

func _init(type: String) -> void:
	self.file_type = file_types[type]
