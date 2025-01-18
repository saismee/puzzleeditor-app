extends Panel

var file_popup: PopupMenu

@onready var Export = get_node("/root/Spatial/Export")

@onready var Voxels = get_node("/root/Spatial/Voxels")
@onready var Entities = get_node("/root/Spatial/Entities")
@onready var Connections = get_node("/root/Spatial/UI/Connections")
@onready var Options = get_node("/root/Spatial/UI/Options")

var entities_popup: SContextMenu

@onready var file_entries = [
	{
		"name": "New Project",
		"function": "new_project"
		
	},
	{
		"name": "Open Project",
		"function": "open_project"
	},
	{
		"name": "Save Project",
		"function": "save_project"
	},
	{
		"separator": true
	},
	{
		"name": "Reload Packages",
		"function": "reload_packages"
	},
	#{
		#"name": "test",
		#"function": (func() -> void:
		#for index in 6:
			#Logger.info(Util.perpendicular_vector(Util.surface_normals[index]))
			#Logger.info(Util.perpendicular_vector(Surface.new(index).to_basis().y))
		#)
	#},
	{
		"separator": true
	},
	{
		"name": "Export Level",
		"function": Export.puzzlemaker_export
	},
	{
		"name": "Build Level",
		"function": Export.puzzlemaker_build
	},
	{
		"name": "Build and Run Level",
		"function": Export.puzzlemaker_build_and_run
	},
	{
		"name": "Hide Build Error",
		"function": Export.unload_pointfile
	},
	{
		"separator": true
	},
	{
		"name": "Options",
		"function": "open_options"
	},
	{
		"name": "Exit",
		"function": "_exit"
	}
]

var entities = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var pop = PopupMenu.new()
	pop.visible = true
	
	file_popup = SContextMenu.new("FILE", _on_item_pressed, self, self)
	file_popup.hide_on_item_selection = true
	file_popup.position = Vector2i(0, 64)
	
	var file_button = get_node("File")
	file_button.pressed.connect(func() -> void:
		file_popup.popup()
	)
	
	for entry in file_entries:
		if entry.has("separator"):
			file_popup.add_separator()
		else:
			file_popup.add_item(entry.name)
			file_popup.set_item_icon(file_popup.item_count - 1, ContentLoader._load("res://themes/perpetual/assets/empty.png"))
	
	entities_popup = SContextMenu.new("ADD ITEM", func(id: int, _menu: SContextMenu):
		var entity: int = Entities.create_entity(entities[id], Surface.new(), Vector3(1, 1, 1), Vector3.ZERO)
		if entity == -1: return
		Entities._generate_entity(entity),
	self, self)
	entities_popup.hide_on_item_selection = true
	entities_popup.position = Vector2i(120, 64)
	
	var entities_button = get_node("Entities")
	entities_button.pressed.connect(func() -> void:
		entities_popup.popup()
	)
	
	
	_update_entities()
	
	set_item_enabled("Hide Build Error", false)

func _on_item_pressed(id: int, _menu: SContextMenu):
	var function: Variant = file_entries[id].function
	if file_entries[id].function is Callable:
		function.call()
	else:
		call(function)

func set_item_enabled(name: String, value: bool) -> void:
	for index: int in file_entries.size():
		if file_entries[index].has("name") and (file_entries[index].name == name):
			file_popup.set_item_disabled(index, !value)
			return

func open_options() -> void:
	Options.show()

func _exit():
	get_tree().quit()

func new_project():
	Voxels.new_project()
	#Entities._new_project()

func open_project() -> void:
	SFileDialog.new(
		FileType.new("EDITOR_FILES"),
		func(file_path: String):
			# won't check this is valid, it should be because of the filedialog
			var file = FileAccess.open(file_path, FileAccess.READ)
			var out = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			json.parse(out)
			Voxels.open_project(json.get_data())
			, # i put this here because the trailing comma looks weird on the above line
		get_parent()
	)

func save_project():
	SFileDialog.new(
		FileType.new("EDITOR_FILES"),
		func(file_path: String):
			# won't check this is valid, it should be because of the filedialog
			Voxels.save_project(file_path)
			, # i put this here because the trailing comma looks weird on the above line
		get_parent(),
		FileDialog.FILE_MODE_SAVE_FILE
	)

func reload_packages():
	Logger.info("RELOADING ASSETS")
#	Entities._unload_entities()
#	Entities._load_entities()
	Data.load_packages()

func _update_entities():
	if !entities_popup: return
	entities = []
	var entities_button = get_node("Entities")
	entities_popup.clear()
	for entity in Data.registered_entities:
		if Util.has(Data.registered_entities[entity].editor, "hidden", false) and (not Util.has(Data.global_config.options, "developer_mode", false)): continue
		
		if Data.registered_entities[entity].has("icon"):
			Logger.info(typeof(Data.registered_entities[entity].icon))
		
		entities_popup.add_item(Data.registered_entities[entity].name)
		#entities_popup.set_item_icon(entities_popup.item_count - 1, Util.has(Data.registered_entities[entity], "icon", ContentLoader._load("res://themes/perpetual/assets/empty.png")))
		entities.append(entity)
