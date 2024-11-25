extends Area2D
class_name DroppedItem

signal collected(item_data: Dictionary)

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

var item_data: Dictionary = {}
var initial_position: Vector2
var target_position: Vector2
var drop_height: float = -50.0
var drop_duration: float = 0.75
var time_elapsed: float = 0.0

func _ready():
	# Set collision layer to something different from enemies/NPCs
	collision_layer = 0b10000  # Layer 5
	collision_mask = 0
	
	# Set up collision detection
	input_event.connect(_on_input_event)

func initialize(data: Dictionary, pos: Vector2):
	item_data = data
	position = pos + Vector2(0, drop_height)  # Start from above
	target_position = pos
	
	# Set sprite based on item type
	if item_data.type == "coin":
		sprite.texture = preload("res://assets/coin.png")
		sprite.hframes = 6  # Adjust this to match your spritesheet
		animation_player.play("spin")

func _physics_process(delta):
	time_elapsed += delta
	
	if time_elapsed <= drop_duration:
		var t = ease(time_elapsed / drop_duration, 0.5)
		position = target_position + Vector2(0, drop_height * (1.0 - t))

func _on_input_event(_viewport, event: InputEvent, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		collect()

func collect():
	collected.emit(item_data)
	queue_free()
