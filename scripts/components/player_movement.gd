class_name PlayerMovement
extends Node

signal jumped
signal landed
signal started_moving
signal stopped_moving
signal dropped_through_platform

@export var config: PlayerConfig
@export var character: CharacterBody2D

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
		# Use acceleration for smoother movement
		character.velocity.x = move_toward(
			character.velocity.x,
			direction * config.get_modified_speed(),
			config.ACCELERATION * get_physics_process_delta_time()
		)
		set_facing_direction(direction)
		started_moving.emit()
	else:
		# Apply friction when not moving
		var friction = config.FRICTION if character.is_on_floor() else config.AIR_RESISTANCE
		character.velocity.x = move_toward(
			character.velocity.x,
			0,
			friction * get_physics_process_delta_time()
		)
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
	var space_state = character.get_world_2d().direct_space_state
	var check_position = character.global_position + Vector2(direction * 10, -5)
	
	var params = PhysicsRayQueryParameters2D.create(
		check_position,
		check_position + Vector2(0, 10),
		1
	)
	
	var result = space_state.intersect_ray(params)
	return result.is_empty()

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
		facing_direction *= -1
		character.scale.x *= -1

func _on_drop_timer_timeout() -> void:
	can_drop_through = true
