class_name SContextMenu extends PopupMenu

var menu: PopupMenu
var shadow: Panel
var titlebar: Label
var sidebar: Panel

var tween: Tween
var target_size: Vector2i

var titlebar_visible: bool = true

var submenus = []

func _init(title: String, function: Callable, parent: Node, shadow_parent: Variant = null, size: Vector2i = Vector2i(300, 20), position: Vector2i = parent.get_viewport().get_mouse_position()) -> void:
#	var menu = PopupMenu.new()
	set_visible(true)
	self.position = position + Vector2i(0, 24)
	self.size = size
	target_size = size
	self.max_size = Vector2i(1, 1)
	self.hide_on_item_selection = false
	
	visible = true
	
	add_theme_stylebox_override("hover", ContentLoader._load("res://themes/perpetual/assets/highlighteddrop.tres"))
	add_theme_stylebox_override("panel", ContentLoader._load("res://themes/perpetual/assets/hidden_panel.tres"))
	
	var shadow = Panel.new()
	shadow.show_behind_parent = true
	shadow.add_theme_stylebox_override("panel", ContentLoader._load("res://themes/perpetual/assets/shadow.tres"))
	
	var titlebar = Label.new()
	titlebar.add_theme_stylebox_override("normal", ContentLoader._load("res://themes/perpetual/assets/contexttitle.tres"))
	titlebar.add_theme_color_override("font_color", Color(1, 1, 1))
	titlebar.text = title
	titlebar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titlebar.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	var sidebar = Panel.new()
	sidebar.add_theme_stylebox_override("panel", ContentLoader._load("res://themes/perpetual/assets/sidebar.tres"))
	sidebar.position = Vector2i(1, 1)
	sidebar.z_index = -1
	
	var backpanel = Panel.new()
	backpanel.add_theme_stylebox_override("panel", ContentLoader._load("res://themes/perpetual/assets/menupanel.tres"))
	backpanel.size = Vector2i(1000, 1000)
	backpanel.z_index = -2
	
	id_pressed.connect(func(id: int) -> void:
		function.call(id, self)
	)
	tree_exiting.connect(func() -> void:
		if tween:
			tween.kill()
		
		get_tree().root.get_node("Spatial/UI").remove_child(shadow)
		shadow.queue_free()

		get_tree().root.get_node("Spatial/UI").remove_child(titlebar)
		titlebar.queue_free()
		
		for submenu: PopupMenu in submenus:
			submenu.queue_free()
	)
	popup_hide.connect(func() -> void:
		size = Vector2i.ZERO
		max_size = Vector2i.ZERO
		shadow.size = Vector2i.ZERO
		titlebar.size = Vector2i.ZERO
		shadow.visible = false
		titlebar.visible = false
	)
	
	about_to_popup.connect(func() -> void:
		set_tween()
	)
	
	size_changed.connect(update_size)
	
#	menu_changed.connect(func() -> void:
#		set_item_icon(item_count - 1, ContentLoader._load("res://themes/perpetual/assets/empty.png"))
#	)
	
#	self.menu = menu
	self.shadow = shadow
	self.titlebar = titlebar
	self.sidebar = sidebar
	
	shadow.visible = false
	titlebar.visible = false
	
	self.update_size()
	
	submenu_popup_delay = 0
	
	parent.add_child(self)
	if !shadow_parent:
		shadow_parent = get_tree().root.get_node("Spatial/UI")
	#get_tree().root.get_node("Spatial/UI").add_child(shadow)
	#get_tree().root.get_node("Spatial/UI").add_child(titlebar)
	shadow_parent.add_child(shadow)
	shadow_parent.add_child(titlebar)
	add_child(sidebar)
	add_child(backpanel)

func add_submenu(label: String, submenu: String, id: int = -1) -> void:
	add_submenu_item(label, submenu, id)
	submenus.append(get_node(submenu))

func update_size() -> void:
#	Logger.info(size)
	self.shadow.size = size
	self.titlebar.size = Vector2i(size.x, 20)
	self.sidebar.size = Vector2i(32, size.y - 2)

func set_tween() -> void:
	shadow.position = position + Vector2i(-4, 3)
	titlebar.position = position - Vector2i(0, 24)
	
	shadow.visible = true
	titlebar.visible = titlebar_visible
	
	var tween_size = self.get_contents_minimum_size()
	var tween = create_tween().set_parallel()
	
#	self.max_size = tween_size
#	self.size = tween_size
	
	tween.tween_property(self, "max_size", Vector2i(1000, 1000), 0.2)
#	self.size = target_size
	tween.tween_property(self, "size", target_size, 0.1)
#	Logger.info(tween_size)

#func add_item(label: String, id: int = -1, accel: Key = 0) -> void:
#	self.menu.add_item(label, id, accel)
#	self.menu.set_item_icon(self.menu.item_count - 1, ContentLoader._load("res://themes/perpetual/assets/empty.png"))
#	self.update_size()

#func set_item_icon(id: int, icon: Texture2D) -> void:
#	self.menu.set_item_icon(id, icon)
