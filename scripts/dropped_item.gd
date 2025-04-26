extends Area2D
class_name DroppedItem

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

var item_data: Dictionary = {}
var initial_position: Vector2
var target_position: Vector2
var drop_height: float = -50.0
var drop_duration: float = 0.75
var time_elapsed: float = 0.0

func _ready():
	# Set collision layer to Layer 5 (Items)
	collision_layer = 0b10000  # Layer 5
	collision_mask = 0  # We don't need to detect collisions with anything
	
	# Set up collision detection
	input_event.connect(_on_input_event)

func initialize(data: Dictionary, pos: Vector2):
	item_data = data
	position = pos + Vector2(0, drop_height)  # Start from above
	target_position = pos
	
	# Set sprite based on item type
	match item_data.type:
		"coin":
			sprite.texture = preload("res://assets/coin.png")
			sprite.hframes = 6
			animation_player.play("spin")
		"inventory_item":
			var item: ItemData = item_data.item
			sprite.texture = item.icon
			sprite.hframes = 1

func _physics_process(delta):
	time_elapsed += delta
	
	if time_elapsed <= drop_duration:
		var t = ease(time_elapsed / drop_duration, 0.5)
		position = target_position + Vector2(0, drop_height * (1.0 - t))

func _on_input_event(_viewport, event: InputEvent, _shape_idx):
	# Remove this part since we're handling collection through PlayerInteraction now
	pass

func collect():
	print("Collecting item:", item_data)
	EventBus.publish_item_collected(item_data)
	
	match item_data.type:
		"coin":
			print("Publishing coin gain:", item_data.value)
			EventBus.publish_coins_gained(item_data.value)
		"inventory_item":
			print("Publishing inventory item collection:", item_data.item.name)
			EventBus.publish_inventory_item_collected(item_data.item)
	
	queue_free()
