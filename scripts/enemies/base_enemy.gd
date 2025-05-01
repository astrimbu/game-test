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
	
	# Connect animation finished signal
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

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
		
	print("DEBUG: [%s] die() called" % self.name)
	is_dead = true
	velocity = Vector2.ZERO
	
	# Store respawn info before freeing
	var type = enemy_type
	var pos = spawn_position
	var should_spawn = should_respawn
	print("DEBUG: [%s] should_spawn = %s" % [self.name, should_spawn]) # Check respawn flag
	
	# Update player resources through EventBus
	print("DEBUG: [%s] Publishing XP/Kill events" % self.name)
	EventBus.publish_xp_gained(xp_value)
	EventBus.publish_enemy_killed(self)
	
	# Spawn dropped items
	print("DEBUG: [%s] Spawning dropped items" % self.name)
	spawn_dropped_items()
	
	print("DEBUG: [%s] Checking for 'death' animation..." % self.name)
	# Play death animation if it exists
	if animation_player.has_animation("death"): # Changed from "die" to "death" to match user's animation name
		print("DEBUG: [%s] Found 'death' animation. Playing..." % self.name)
		animation_player.play("death")
		print("DEBUG: [%s] Hiding health bar" % self.name)
		# Hide health bar immediately
		health_bar.hide()
		print("DEBUG: [%s] Disabling physics/process" % self.name)
		# Disable collision during animation
		set_physics_process(false)
		set_process(false)
		print("DEBUG: [%s] Checking/Disabling CollisionShape2D" % self.name)
		if has_node("CollisionShape2D"): # Check if collision shape exists
			get_node("CollisionShape2D").set_deferred("disabled", true)
		print("DEBUG: [%s] Finished disabling collision" % self.name)
	else:
		# If no animation, hide immediately
		print("DEBUG: [%s] No 'death' animation found. Hiding immediately." % self.name)
		hide()
		# Request respawn if needed (and no animation)
		if should_spawn:
			print("DEBUG: [%s] Requesting respawn (no animation) in %.1fs" % [self.name, RESPAWN_DELAY])
			get_tree().create_timer(RESPAWN_DELAY).call_deferred("request_respawn", type, pos)
		queue_free() # Free immediately if no animation
		return # Exit early if no animation
	
	# Request respawn after starting animation (if needed)
	print("DEBUG: [%s] Checking if respawn timer should be started..." % self.name)
	if should_spawn:
		print("DEBUG: [%s] Creating respawn timer (%.1fs)..." % [self.name, RESPAWN_DELAY])
		var respawn_timer = get_tree().create_timer(RESPAWN_DELAY)
		print("DEBUG: [%s] Connecting timer timeout to request_respawn(%s, %s)..." % [self.name, type, pos])
		respawn_timer.timeout.connect(request_respawn.bind(type, pos))
		print("DEBUG: [%s] Respawn timer connection attempted." % self.name)
	
	print("DEBUG: [%s] die() function finished (Node not freed here)." % self.name)
	# Node is NOT freed here anymore, it's hidden in _on_animation_finished

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
	# Only bats have a chance to drop items for now.
	if enemy_type == "bat":
		var drop_roll = randf()
		if drop_roll < 0.33: # 33% chance for hat
			return preload("res://scripts/resources/hat1.tres")
		elif drop_roll < 0.66: # 33% chance for sword
			return preload("res://scripts/resources/wooden_sword.tres")

	# Other enemies drop nothing for now, or bat failed the roll.
	return null

func _on_item_collected(item_data: Dictionary):
	if item_data.type == "coin":
		GameState.player_data.coins += item_data.value
		GameState.emit_resource_signal("coins_changed", GameState.player_data.coins)

func respawn():
	print("DEBUG: [%s] respawn() called" % self.name)
	# Reset position and state
	global_position = initial_position
	current_health = max_health
	is_dead = false
	is_being_hit = false
	health_bar.value = current_health
	
	# Show enemy node, sprite, and health bar
	show()
	if sprite:
		sprite.show()
	health_bar.show()
	
	# Re-enable physics and collision
	set_physics_process(true)
	set_process(true)
	if has_node("CollisionShape2D"): # Check if collision shape exists
		get_node("CollisionShape2D").set_deferred("disabled", false)
	
	# Play idle animation if it exists
	if animation_player.has_animation("idle"):
		animation_player.play("idle")
	
	# Reset movement controller
	movement_controller.reset_movement()
	print("DEBUG: [%s] respawn() finished" % self.name)

func get_is_dead() -> bool:
	return is_dead

# Called when any animation finishes
func _on_animation_finished(anim_name):
	print("DEBUG: [%s] _on_animation_finished called with anim_name: %s" % [self.name, anim_name])
	# Check if the death animation finished
	if anim_name == "death":
		print("DEBUG: [%s] 'death' animation finished. Hiding sprite." % self.name)
		# Hide the sprite (or the whole node)
		if sprite:
			sprite.hide()
		# self.hide() # Alternatively hide the whole enemy node
		
		# If the enemy should be removed completely *after* animation:
		# queue_free()
		
		# If respawn is handled by hiding/showing, ensure physics/collision are re-enabled on respawn

func request_respawn(type: String, pos: Vector2):
	print("DEBUG: [%s] request_respawn() called by timer. Calling EventBus helper: publish_request_enemy_spawn(%s, %s)" % [self.name, type, pos])
	EventBus.publish_request_enemy_spawn(type, pos)
