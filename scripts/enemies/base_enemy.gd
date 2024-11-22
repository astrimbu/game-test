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

func _ready():
	# Validate required nodes
	assert(sprite != null, "Sprite node not found at specified path")
	assert(animation_player != null, "AnimationPlayer node not found at specified path")
	assert(health_bar != null, "HealthBar node not found at specified path")
	
	current_health = max_health
	setup_health_bar()
	_init_enemy()

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
	
	move_and_slide()

func hit(attack_position: Vector2):
	if is_dead:
		return
		
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
	
	# Drop rewards
	player.resources.add_xp(xp_value)
	player.resources.add_coins(coin_value)
	
	# Hide the enemy
	hide()
	health_bar.hide()
	
	# Start respawn timer
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	respawn()

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

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_global_mouse_position().distance_to(global_position) < sprite.texture.get_width() / 2:
			player.set_target_enemy(self)
