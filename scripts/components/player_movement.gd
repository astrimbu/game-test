class_name PlayerMovement
extends Node

signal jumped
signal landed
signal started_moving
signal stopped_moving
signal dropped_through_platform

@export var config: PlayerConfig
@export var character: CharacterBody2D

@onready var collision_shape: CollisionShape2D = character.get_node("CollisionShape2D") # Adjust path if needed

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_direction: float = 1
var can_drop_through: bool = true
var drop_timer: Timer

func _ready() -> void:
	drop_timer = Timer.new()
	drop_timer.one_shot = true
	add_child(drop_timer)
	drop_timer.timeout.connect(_on_drop_timer_timeout)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	character.move_and_slide()

func apply_gravity(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y += gravity * delta

func jump() -> void:
	if character.is_on_floor() and has_platform_above():
		character.velocity.y = config.get_modified_jump()
		jumped.emit()

func move(direction: float) -> void:
	if direction != 0:
		# Set velocity directly for instantaneous movement
		character.velocity.x = direction * config.get_modified_speed()
		set_facing_direction(direction)
		started_moving.emit()
	else:
		# Instantly stop horizontal movement when input is zero
		character.velocity.x = 0
		stopped_moving.emit()

func drop_through_platform() -> void:
	if not can_drop_through or not has_platform_below():
		return
		
	# Temporarily disable collision with one-way platforms
	character.set_collision_mask_value(1, false)
	can_drop_through = false
	dropped_through_platform.emit()
	
	# Add a small downward velocity to ensure we start falling
	character.velocity.y = 10
	
	# Create a timer to re-enable collision after a short duration
	var timer = character.get_tree().create_timer(0.1)  # Shorter duration
	timer.timeout.connect(func():
		character.set_collision_mask_value(1, true)
		
		# Add a small delay before allowing another drop
		character.get_tree().create_timer(0.2).timeout.connect(func():
			can_drop_through = true
		)
	)

func will_fall_off_edge(direction: float) -> bool:
	if not character.is_on_floor(): # Only check for falling off edges if currently on the floor
		return false

	# Parameters for testing
	var step_forward_distance = 5.0 # How far ahead to check horizontally (adjust as needed)
	var step_down_distance = 10.0  # How far down to check from the forward position (adjust as needed)

	# Simulate moving slightly forward
	var forward_motion = Vector2(direction * step_forward_distance, 0)

	# Get the transform the character would have after moving forward
	# Note: CharacterBody2D transform doesn't update immediately with velocity,
	# so we calculate the potential future transform based on current position.
	var future_transform = character.transform.translated(forward_motion)
	
	# Define the downward motion to test for ground
	var down_motion = Vector2(0, step_down_distance)

	# Test moving down from the potential future position.
	# test_move returns true if a collision *would* occur.
	if not character.test_move(future_transform, down_motion):
		# If test_move is false, it means NO collision would occur moving down -> potential edge
		# print("DEBUG: test_move detected potential edge fall!") # Optional Debug
		return true # No ground detected below the forward position -> will fall
	else:
		# If test_move is true, it means a collision *would* occur -> ground is present
		return false # Ground detected -> won't fall

func has_platform_below() -> bool:
	var space_state = character.get_world_2d().direct_space_state
	var params = PhysicsRayQueryParameters2D.create(
		character.global_position,
		character.global_position + Vector2(0, config.DROP_CHECK_DISTANCE),
		1
	)
	
	var results = space_state.intersect_ray(params)
	return results and results.position.y > character.global_position.y + 10

func has_platform_above() -> bool:
	var space_state = character.get_world_2d().direct_space_state
	var params = PhysicsRayQueryParameters2D.create(
		character.global_position,
		character.global_position + Vector2(0, -config.JUMP_CHECK_DISTANCE),
		1
	)
	
	var results = space_state.intersect_ray(params)
	return results and results.position.y < character.global_position.y - 10 

func set_facing_direction(direction: float) -> void:
	if direction != facing_direction:
		print("DEBUG: set_facing_direction called with NEW direction: ", direction, ", current facing_direction: ", facing_direction) # DEBUG
		print("DEBUG: character.scale.x BEFORE flip: ", character.scale.x) # DEBUG
		print("DEBUG: Flipping scale!") # DEBUG
		facing_direction = direction # Correctly update facing_direction
		character.scale.x *= -1
		print("DEBUG: character.scale.x AFTER flip: ", character.scale.x) # DEBUG

func _on_drop_timer_timeout() -> void:
	can_drop_through = true
