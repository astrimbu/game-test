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
var bobbing_amplitude: float = 3.0  # How high/low it bobs (pixels)
var bobbing_speed: float = 5.0     # How fast it bobs (radians/sec)
var can_bob: bool = false

func _ready():
	# Set collision layer to Layer 5 (Items)
	collision_layer = 0b10000  # Layer 5
	collision_mask = 0  # We don't need to detect collisions with anything
	
	# Set up collision detection
	input_event.connect(_on_input_event)

func initialize(data: Dictionary, pos: Vector2):
	item_data = data
	initial_position = pos + Vector2(0, drop_height) # Store initial start position if needed
	position = initial_position
	target_position = pos
	can_bob = false # Ensure bobbing starts only after drop
	
	# Set sprite based on item type
	match item_data.type:
		"coin":
			sprite.texture = preload("res://assets/coin.png")
			sprite.hframes = 6
			animation_player.play("spin")
			# Coins already spin, maybe don't bob them, or make it optional
			# can_bob = true # Uncomment if coins should bob too
		"inventory_item":
			var item: ItemData = item_data.item
			sprite.texture = item.icon
			sprite.hframes = 1
			# Enable bobbing for static inventory items
			can_bob = true

func _physics_process(delta):
	time_elapsed += delta
	
	if time_elapsed <= drop_duration:
		# Drop animation
		var t = ease(time_elapsed / drop_duration, 0.5) # Consider using different easing functions (e.g., EASE_OUT_BOUNCE)
		position.y = lerp(initial_position.y, target_position.y, t)
		position.x = target_position.x # Ensure x stays fixed during drop
	elif can_bob:
		# Bobbing animation after drop completes
		var bob_offset = sin(time_elapsed * bobbing_speed) * bobbing_amplitude
		position.y = target_position.y + bob_offset
		# Ensure x is correct if it drifted somehow
		position.x = target_position.x

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
