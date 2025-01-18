extends Node

@onready var Ribbon = get_tree().root.get_node("Spatial/UI/Ribbon")
@onready var Palette = get_tree().root.get_node("Spatial/UI/Palette/Palette")
@onready var Options = get_tree().root.get_node("Spatial/UI/Options")

@onready var meta = ContentLoader._loadjson("res://packages/meta.json")

var registered_skins = {}
var registered_entities = {}

var voxels = {}
var entities = []
var skin = "clean"

var connections = 0

var global_config = {
	games = {},
	build = 0,
	verbose = 0,
	options = {
		developer_mode = 0,
		console_enabled = 0
	}
}
var game = "Portal 2"

var grid_size: float = 32.0/128.0

var version = "0.0.6"
var build = 2409

@onready var development = OS.is_debug_build()

func check_version(id: String, type: String, version: int) -> void:
	if version < meta[type + "_version"]:
		Logger.warn(id + " is out of date! (Version " + str(version) + " < " + str(meta[type + "_version"]) + ")")
		SPopup.new("Entity out of date", id + " is out of date! (Version " + str(version) + " < " + str(meta[type + "_version"]) + ")\nSome features may not function correctly!", "Ignore")

# Loaders
func load_entity(id: String) -> void:
	if registered_entities.has(id): return
	Logger.info("Loading Entity: " + id)
	var entity = ContentLoader._loadspecial("entity", id)
	
	if entity:
		registered_entities[id] = entity
		check_version(id, "entity", Util.has(entity, "editor_version", 0))

func load_skin(id: String) -> void:
	if registered_skins.has(id): return
	Logger.info("Loading Skin: " + id)
	var skin = ContentLoader._loadspecial("skin", id)
	
	if skin:
		registered_skins[id] = skin
		check_version(id, "skin", skin.editor_version)

func fixup(text: String, values: Dictionary):
	for key in values:
		text = text.replace("$" + key, values[key])
	return text

func add_game(name: String, exe_path: String) -> Variant:
	# returns null on success, and a string with the failed step otherwise.
	var paths: PackedStringArray = exe_path.split("/")
	var directory: PackedStringArray = paths[paths.size() - 1].split(".")
	var id: String = directory[0]
	var extension: String = directory[1]
	paths.resize(paths.size() - 1)
	var path = "/".join(paths)
	# i dont like this, but there doesnt seem to be another way to get the parent directory
	
	var new_config = {
		executable = exe_path,
		launch_args = "",
		id = id,
		path = path,
		compilers = {}
	}
	if extension == "bat":
		new_config.executable = path + "/bin/win64/chaos.exe" # hacky strata support
		new_config.launch_args = "-game " + id
	
	if FileAccess.file_exists(path + "/bin/win64/vbsp.exe"):        # strata source compilers
		new_config.compilers.vbsp = path + "/bin/win64/vbsp.exe"
	elif FileAccess.file_exists(path + "/bin/vbsp_original.exe"):   # beemod compilers
		new_config.compilers.vbsp = path + "/bin/vbsp_original.exe"
	elif FileAccess.file_exists(path + "/bin/vbsp.exe"):            # source compilers
		new_config.compilers.vbsp = path + "/bin/vbsp.exe"
	else:
		return "vbsp.exe"
	
	if FileAccess.file_exists(path + "/bin/win64/vvis.exe"):        # strata source compilers
		new_config.compilers.vvis = path + "/bin/win64/vvis.exe"
	elif FileAccess.file_exists(path + "/bin/vvis.exe"):            # source compilers
		new_config.compilers.vvis = path + "/bin/vvis.exe"
	else:
		return "vvis.exe"
	
	if FileAccess.file_exists(path + "/bin/win64/vrad.exe"):        # strata source compilers
		new_config.compilers.vrad = path + "/bin/win64/vrad.exe"
	elif FileAccess.file_exists(path + "/bin/vrad_original.exe"):   # beemod compilers
		new_config.compilers.vrad = path + "/bin/vrad_original.exe"
	elif FileAccess.file_exists(path + "/bin/vrad.exe"):            # source compilers
		new_config.compilers.vrad = path + "/bin/vrad.exe"
	else:
		return "vrad.exe"
	
	global_config.games[name] = new_config
	save_global_config()
	Logger.info("Generating compiler files for " + name)
	DirAccess.make_dir_absolute("user://compile")
	
	var rep = {
		"path" = new_config.path,
		"id" = new_config.id,
		"executable" = new_config.executable,
		"vbsp" = new_config.compilers.vbsp,
		"vvis" = new_config.compilers.vvis,
		"vrad" = new_config.compilers.vrad,
	}
	
	var win_comp_template = FileAccess.open("res://compile/template_full_windows.bat", FileAccess.READ)
	var out = FileAccess.open("user://compile/" + name.replace(" ", "-") + "_full_windows.bat", FileAccess.WRITE)
	var string = fixup(win_comp_template.get_as_text(), rep).replace("/", "\\")
	out.store_string(string)
	
	var template = FileAccess.open("res://compile/template_exec_windows.bat", FileAccess.READ)
	out = FileAccess.open("user://compile/" + name.replace(" ", "-") + "_exec_windows.bat", FileAccess.WRITE)
	out.store_string(fixup(template.get_as_text(), rep).replace("/", "\\"))
	
	win_comp_template.close()
	template.close()
	
	Logger.info("Added new game: " + name)
	Logger.info(new_config)
	Options.update_games()
	return null

func find_game(name: String) -> void:
	if global_config.games.has(name): return
	# find the default library
	var dir
	var os = OS.get_name()
	match os:
		"Windows", "UWP":
			dir = "C:/Program Files (x86)/Steam/steamapps/common"
#			dir = "D:/SteamLibrary/steamapps/common"
		"macOS":
			dir = "~/Library/Application Support/Steam/steamapps/common"
		#"Linux":
			#dir = "~/.steam/steam/SteamApps/common"
	
	# TODO: search other steam library
	
	if dir == null:
		Logger.warn("Unsupported OS: " + os)
		SPopup.new("Unsupported OS", "PuzEdit does not support compiling on your operating system.\nYou are using: " + os + ".\nPuzEdit supports: Windows")
		return
	
	if !DirAccess.dir_exists_absolute(dir):
		Logger.warn("Failed to locate Steam library")
		SPopup.new("Failed to locate Steam library", "Failed to locate your Steam library in '" + dir + "'!\nAdd a game manually in File > Options > Games")
		return
	
	if !DirAccess.dir_exists_absolute(dir + "/" + name):
		Logger.warn("Failed to locate " + name)
		SPopup.new("Failed to locate " + name, "Failed to locate '" + name + "' at '" + dir + "/" + name + "'!\nAdd a game manually in File > Options > Games")
		return
	# found the game
	
	var executable = Util.iterate_dir(dir + "/" + name, func(name) -> Variant:
		var split = name.split(".")
		if split.size() == 2 and split[1] == "exe":
			return name
		return null
	)
	
	if executable == null:
		Logger.warn("Failed to locate executable for " + name)
		SPopup.new("Failed to locate executable", "Failed to locate executable for '" + name + "' at '" + dir + "/" + name + "'!\nAdd a game manually in File > Options > Games")
		return
	
	add_game(name, dir + "/" + name + "/" + executable)

func load_packages() -> void:
	registered_skins = {}
	registered_entities = {}
	
	Util.iterate_dir("res://packages/entity", load_entity)
	Util.iterate_dir("user://packages/entity", load_entity)
	
	Util.iterate_dir("res://packages/skin", load_skin)
	Util.iterate_dir("user://packages/skin", load_skin)
	
#	for index in Data.entities.size():
#		if !Data.registered_entities.has(Data.entities[index].name):
#			Logger.warn("Entity " + Data.entities[index].name + " is missing! Removing...")
#			Selection._select_entity(null)
#			Selection.selection_entity_index = null
#			Selection.selection_entity_object = null
#			_remove_entity(index)
	
	Palette.update_palette()

func save_global_config() -> void:
	var file = FileAccess.open("user://global_config.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(global_config))
	file.close()

func load_global_config() -> void:
	Logger.info("Loading global config")
	Logger.info("Debug Mode: " + str(development))
	if FileAccess.file_exists("user://global_config.json"):
		var config = ContentLoader._loadjson("user://global_config.json")
		for entry in config:
			global_config[entry] = config[entry]
		
		if development:
			Logger.info(global_config.build)
			global_config.build += 1
			save_global_config()
	if !development:
		global_config.build = build
	get_tree().root.get_node("Spatial/UI/Inner/Build").text = "Version " + str(version) + "-" + str(global_config.build)
	Logger.log_verbose = bool(global_config.verbose)
	get_tree().root.get_node("Spatial/UI/Inner/Output").visible = bool(global_config.options.developer_mode)
	Logger.info("Global config loaded")

func _ready():
	load_global_config()
	
	ContentLoader.generate_default_directories()
	find_game("Portal 2")
#	find_game("Half-Life 2")
#	game = "Half-Life 2"
	load_packages()
