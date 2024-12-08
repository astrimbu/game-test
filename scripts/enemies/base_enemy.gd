extends CharacterBody2D
class_name Enemy

const KNOCKBACK_FORCE = 20
const KNOCKBACK_DURATION = 0.3
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

@export var dropped_item_scene: PackedScene = preload("res://scenes/DroppedItem.tscn")
@onready var movement_controller: EnemyMovementController = $MovementController

signal enemy_died(enemy: Enemy)
signal enemy_respawned(enemy: Enemy)

func _ready():
	# Validate required nodes
	assert(sprite != null, "Sprite node not found at specified path")
	assert(animation_player != null, "AnimationPlayer node not found at specified path")
	assert(health_bar != null, "HealthBar node not found at specified path")
	
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

func hit(attack_position: Vector2):
	if is_dead:
		return
		
	movement_controller.stop_movement()  # Stop movement when hit
	is_being_hit = true
	knockback_timer = KNOCKBACK_DURATION
	knockback_direction = (global_position - attack_position).normalized()
	
	# Apply damage
	current_health -= damage_per_hit
	health_bar.value = current_health
	
	# Check for death
	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	
	# Play death animation if it exists
	if animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished
	
	# Grant XP to player
	if xp_value > 0:
		player.resources.add_xp(xp_value)
	
	# Drop coins as physical items
	if coin_value > 0:
		var dropped_item = dropped_item_scene.instantiate()
		get_parent().add_child(dropped_item)
		dropped_item.initialize({
			"type": "coin",
			"value": coin_value
		}, global_position)
		dropped_item.collected.connect(_on_item_collected)
	
	# Store references before removing from scene
	var parent = get_parent()
	var tree = get_tree()
	
	# Emit signal and remove from scene
	enemy_died.emit(self)
	parent.remove_child(self)
	
	# Create timer while we still have tree access
	var timer = tree.create_timer(RESPAWN_DELAY)
	await timer.timeout
	
	# Add back to scene tree and respawn
	parent.add_child(self)
	respawn()

func _on_item_collected(item_data: Dictionary):
	if item_data.type == "coin":
		player.resources.add_coins(item_data.value)

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
	
	# Emit respawn signal
	enemy_respawned.emit(self)
