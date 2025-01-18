extends Button

var tween: Tween
var image: TextureRect
var entity_name: String

@onready var Entities = get_node("/root/Spatial/Entities")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	image = get_node("Image")
	
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)

func _mouse_entered() -> void:
	if tween: tween.kill()
	tween = get_tree().create_tween().set_parallel()
	tween.tween_property(image, "scale", Vector2(1.25, 1.25), 0.1)
	tween.tween_property(image, "position", Vector2(-10, -10), 0.1)

func _mouse_exited() -> void:
	if tween: tween.kill()
	tween = get_tree().create_tween().set_parallel()
	tween.tween_property(image, "scale", Vector2(1, 1), 0.1)
	tween.tween_property(image, "position", Vector2(0, 0), 0.1)

func _pressed() -> void:
	var entity: int = Entities.create_entity(entity_name, Surface.new(), Vector3(1, 1, 1), Vector3.ZERO)
	if entity == -1: return
	Entities._generate_entity(entity)
