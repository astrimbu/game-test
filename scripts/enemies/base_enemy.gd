class_name BaseEnemy
extends CharacterBody2D

const KNOCKBACK_FORCE = 20.0
const KNOCKBACK_DURATION = 0.2
const RESPAWN_DELAY = 3.0

# Make these configurable per enemy type
@export var max_health := 10
@export var damage_per_hit := 2
@export var xp_value: int = 1
@export var coin_value: int = 1
@export var indicator_offset := 64.0

# Required node paths
@export var sprite_path: NodePath
@export var animation_player_path: NodePath
@export var health_bar_path: NodePath

# Onready vars using the paths
@onready var sprite = get_node(sprite_path)
@onready var animation_player = get_node(animation_player_path)
@onready var health_bar = get_node(health_bar_path)
@onready var player = $"../Player"
@onready var initial_position = global_position

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_being_hit = false
var knockback_direction = Vector2.ZERO
var knockback_timer = 0.0
var current_health
var is_dead = false

@onready var movement_controller: EnemyMovementController = $MovementController

# Add a new resource type for enemy configuration
@export var enemy_config: Resource

@export var enemy_type: String = "bat"  # Used for respawning
@export var should_respawn: bool = true
var spawn_position: Vector2

func _ready():
	# Validate required nodes
	assert(sprite != null, "Sprite node not found at specified path")
	assert(animation_player != null, "AnimationPlayer node not found at specified path")
	assert(health_bar != null, "HealthBar node not found at specified path")
	
	spawn_position = global_position  # Store initial spawn position
	current_health = max_health
	setup_health_bar()
	_init_enemy()
	movement_controller.init(sprite)

# Virtual method for child classes to override
func _init_enemy():
	pass

func setup_health_bar():
	# Update health bar to match current health
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.show()

func _physics_process(delta):
	if is_dead:
		return
		
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle knockback
	if is_being_hit:
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_being_hit = false
			velocity = Vector2.ZERO
		else:
			velocity = knockback_direction * KNOCKBACK_FORCE
	else:
		velocity.x = movement_controller.process_movement(delta).x
	
	move_and_slide()

func take_damage(amount: int) -> void:
	if is_dead:
		return
		
	current_health -= amount
	health_bar.value = current_health
	
	# Start knockback/hit animation
	is_being_hit = true
	knockback_timer = KNOCKBACK_DURATION
	
	# Get knockback direction from player
	var player = get_node("../Player")  # Adjust path if needed
	if player:
		knockback_direction = (global_position - player.global_position).normalized()
	
	# Apply status effect (stunned during knockback)
	EventBus.publish_status_effect(self, "stunned", KNOCKBACK_DURATION)
	
	# Check if enemy died from this hit
	if current_health <= 0:
		die()
	else:
		EventBus.enemy_hit.emit(self)

func die() -> void:
	if is_dead:
		return
		
	is_dead = true
	velocity = Vector2.ZERO
	
	# Store respawn info before freeing
	var type = enemy_type
	var pos = spawn_position
	var should_spawn = should_respawn
	
	# Update player resources through EventBus
	EventBus.publish_xp_gained(xp_value)
	EventBus.publish_enemy_killed(self)
	
	# Spawn dropped items
	spawn_dropped_items()
	
	if animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished
	
	# Request respawn before freeing if needed
	if should_spawn:
		await get_tree().create_timer(RESPAWN_DELAY).timeout
		EventBus.request_enemy_spawn(type, pos)
	
	queue_free()

func spawn_dropped_items() -> void:
	# Spawn coin
	if coin_value > 0:
		spawn_world_item({
			"type": "coin",
			"value": coin_value
		})
	
	# Attempt to get a random drop
	var item = get_random_drop()
	if item:
		spawn_world_item({
			"type": "inventory_item",
			"item": item
		})

func spawn_world_item(item_data: Dictionary) -> void:
	# Always use the main dropped item scene.
	# Its initialize function will handle the specific type (coin vs inventory_item).
	var scene_to_spawn = preload("res://scenes/DroppedItem.tscn")

	var dropped_item = scene_to_spawn.instantiate()
	get_parent().add_child(dropped_item)
	dropped_item.initialize(item_data, global_position)

func get_random_drop() -> ItemData:
	# Only bats have a chance to drop the wooden sword for now.
	if enemy_type == "bat":
		if randf() < 0.2: # 1/5 chance
			return preload("res://scripts/resources/wooden_sword.tres")
	
	# Other enemies drop nothing for now, or bat failed the roll.
	return null

func _on_item_collected(item_data: Dictionary):
	if item_data.type == "coin":
		GameState.player_data.coins += item_data.value
		GameState.emit_resource_signal("coins_changed", GameState.player_data.coins)

func respawn():
	# Reset position and state
	global_position = initial_position
	current_health = max_health
	is_dead = false
	is_being_hit = false
	health_bar.value = current_health
	
	# Show enemy and health bar
	show()
	health_bar.show()
	
	# Play idle animation if it exists
	if animation_player.has_animation("idle"):
		animation_player.play("idle")
	
	# Reset movement controller
	movement_controller.reset_movement()

func get_is_dead() -> bool:
	return is_dead
