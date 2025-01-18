extends Node

@onready var window: Window = get_node("Window")
@onready var Voxels: MeshInstance3D = get_tree().root.get_node("Spatial/Voxels")
@onready var Ribbon: Node = get_tree().root.get_node("Spatial/UI/Ribbon")

var game_popup: PopupMenu

var options = {
	"console_enabled": 0,
	"developer_mode": 0,
}

# Called when the node enters the scene tree for the first time.
func _ready():
	# create window
	
	window.size = Vector2i(600, 400)
	window.position = Vector2i(get_viewport().size.x / 2 - 300, get_viewport().size.y / 2 - 200)
	window.theme = ContentLoader._load("res://themes/perpetual/perpetual_dialog.tres")
	
	window.close_requested.connect(hide)
	
	for option: String in options:
		if Data.global_config.options.has(option): continue
		Data.global_config.options[option] = options[option]
	
	# CONSOLE TOGGLE
	var console_toggle = window.get_node("VBoxContainer/Console")
	console_toggle.set_pressed(Data.global_config.options.console_enabled == 1)
	Logger.set_console_visible(Data.global_config.options.console_enabled == 1)
	console_toggle.toggled.connect(func(on: bool) -> void:
		Data.global_config.options.console_enabled = int(on)
		Logger.set_console_visible(on)
		update_settings()
	)
	
	# DEVELOPER MODE
	var developer_toggle = window.get_node("VBoxContainer/Developer")
	developer_toggle.set_pressed(Data.global_config.options.developer_mode)
	developer_toggle.toggled.connect(func(on: bool) -> void:
		Data.global_config.options.developer_mode = int(on)
		update_settings()
		Voxels.save_project("user://autosave.se")
		Data.load_packages()
	)
	
	# ADD GAMES
	var add_game: Button = window.get_node("VBoxContainer/AddGame")
	add_game.pressed.connect(func() -> void:
		SFileDialog.new(
			FileType.new("GAME_EXECUTABLES"),
			func(file_path: String) -> void:
				#Logger.info(file_path)
				var directories = file_path.split("/")
				#Logger.info(directories)
				Data.add_game(directories[directories.size()-2], file_path)
				, # i put this here because the trailing comma looks weird on the above line
			get_parent(),
			FileDialog.FILE_MODE_OPEN_FILE,
			FileDialog.ACCESS_FILESYSTEM
		)
	)
	
	var select_game: MenuButton = window.get_node("VBoxContainer/SelectGame")
	game_popup = select_game.get_popup()
	update_games()
	
	game_popup.id_pressed.connect(func(id: int) -> void:
		Data.game = game_popup.get_item_text(id)
		update_games()
	)

func update_games() -> void:
	if game_popup == null: return
	game_popup.clear()
	for game in Data.global_config.games:
		game_popup.add_item(game)
	window.get_node("VBoxContainer/SelectGame").text = "Current Game: " + Data.game

func update_settings() -> void:
	Data.save_global_config()

func show():
	window.show()

func hide():
	window.hide()
