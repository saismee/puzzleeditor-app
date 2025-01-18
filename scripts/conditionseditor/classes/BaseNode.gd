class_name CEBaseNode
extends GraphNode

func _init(name: String, pos: Vector2i = Vector2i.ZERO, parent: Variant = null) -> void:
	title = name #inherited from GraphNode
	resizable = true
	size = Vector2(200, 100)
	if parent:
		parent.add_child(self)
	position_offset = pos
	
	_init2()
	
	var close: Button = Button.new()
	close.text = "x"
	close.pressed.connect(func() -> void:
		queue_free()
	)
	get_titlebar_hbox().add_child(close)

func _init2() -> void:
	pass

func add_control(key: String) -> void:
	var new_control = LineEdit.new()
	new_control.text = key
	new_control.editable = false
	new_control.custom_minimum_size = Vector2(0, 30)
	add_child(new_control)

func add_string_control(key: String, value: String, name: String = "Node") -> void:
	var new_control := HBoxContainer.new()
	new_control.name = name
	
	var keytext = LineEdit.new()
	keytext.name = "key"
	keytext.text = key
	keytext.custom_minimum_size = Vector2(0, 30)
	keytext.editable = false
	keytext.size_flags_horizontal = SIZE_EXPAND + SIZE_FILL
	new_control.add_child(keytext)
	
	var textedit = LineEdit.new()
	textedit.name = "value"
	textedit.text = value
	textedit.custom_minimum_size = Vector2(0, 30)
	textedit.size_flags_horizontal = SIZE_EXPAND + SIZE_FILL
	new_control.add_child(textedit)
	
	add_child(new_control)
