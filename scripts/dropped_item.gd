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

# Bobbing parameters
var bobbing_amplitude: float = 3.0
var bobbing_speed: float = 5.0
var can_bob: bool = false

func _ready():
	collision_layer = 0b10000  # Layer 5 (Items)
	collision_mask = 0
	input_event.connect(_on_input_event)

func initialize(data: Dictionary, pos: Vector2):
	item_data = data
	# Reset defaults before applying item-specific data
	sprite.scale = Vector2(1, 1)
	target_position = pos 
	
	can_bob = false # Default bobbing state

	match item_data.type:
		"coin":
			sprite.texture = preload("res://assets/coin.png")
			sprite.hframes = 6
			animation_player.play("spin")
			# No scale/offset/bobbing needed for coins usually
		"inventory_item":
			var item: ItemData = item_data.get("item")
			if not item:
				printerr("DroppedItem initialized with 'inventory_item' type but missing ItemData!")
				queue_free()
				return
				
			# Apply settings from ItemData
			sprite.texture = item.icon
			sprite.hframes = 1
			sprite.scale = item.dropped_scale # Use scale from ItemData
			target_position = pos + item.dropped_offset # Use offset from ItemData
			can_bob = true # Allow bobbing for inventory items (Consider making this a bool in ItemData too?)
		_:
			printerr("Unknown item type in DroppedItem: ", item_data.type)
			queue_free() # Or handle fallback appearance
			return

	# Calculate drop start based on final target position
	initial_position = target_position + Vector2(0, drop_height)
	position = initial_position


func _physics_process(delta):
	time_elapsed += delta
	
	if time_elapsed <= drop_duration:
		# Drop animation
		var t = ease(time_elapsed / drop_duration, 0.5)
		position.y = lerp(initial_position.y, target_position.y, t)
		position.x = target_position.x 
	elif can_bob:
		# Bobbing animation
		var bob_offset = sin(time_elapsed * bobbing_speed) * bobbing_amplitude
		position.y = target_position.y + bob_offset
		position.x = target_position.x

func _on_input_event(_viewport, event: InputEvent, _shape_idx):
	pass # Collection handled by PlayerInteraction

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
