extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -300.0
var target_position = null
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var ray_length = 100
const DROP_THROUGH_DURATION = 0.2
const DROP_CHECK_DISTANCE = 400  # Maximum distance to check for platforms below
var can_drop_through = true
var last_direction = 1  # 1 for right, -1 for left
var is_shooting = false
const JUMP_CHECK_DISTANCE = 100  # Distance to check for platforms above

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

# Define states
enum State { IDLE, WALKING, JUMPING, MOVING_TO_TARGET, SHOOTING }
var current_state = State.IDLE

func get_walkable_position(clicked_pos: Vector2) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	
	# First try a direct ray at the click position
	var params = PhysicsRayQueryParameters2D.create(
		clicked_pos + Vector2(0, -5),  # Start just slightly above click
		clicked_pos + Vector2(0, 10),   # End just slightly below click
		1  # Ground layer
	)
	
	var result = space_state.intersect_ray(params)
	if result:
		# If we found a platform right at the click, use it
		return result.position
	
	# If no direct hit, try the longer ray check
	params = PhysicsRayQueryParameters2D.create(
		clicked_pos + Vector2(0, -ray_length),
		clicked_pos + Vector2(0, ray_length),
		1
	)
	
	result = space_state.intersect_ray(params)
	if result:
		var platform_y = result.position.y
		if platform_y >= position.y - 20:
			return Vector2(clicked_pos.x, platform_y)
	
	return position

func _physics_process(delta):
	# Apply gravity first
	if not is_on_floor():
		velocity.y += gravity * delta

	# Then handle states
	match current_state:
		State.IDLE:
			handle_idle_state(delta)
		State.WALKING:
			handle_walking_state(delta)
		State.JUMPING:
			handle_jumping_state(delta)
		State.MOVING_TO_TARGET:
			handle_moving_to_target_state(delta)
		State.SHOOTING:
			handle_shooting_state(delta)
	
	# Apply movement last
	move_and_slide()

func handle_idle_state(delta):
	if Input.is_action_just_pressed("click"):
		var clicked_pos = get_global_mouse_position()
		target_position = get_walkable_position(clicked_pos)
		current_state = State.MOVING_TO_TARGET
		return
	
	# Only process horizontal movement if on floor
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if Input.get_axis("ui_left", "ui_right") != 0:
			current_state = State.WALKING
	
	if not is_shooting:
		animation_player.play("idle")
	sprite.flip_h = last_direction < 0
	
	if Input.is_action_just_pressed("shoot"):
		handle_shoot()
	elif Input.is_action_pressed("ui_accept") and is_on_floor() and has_platform_above():
		current_state = State.JUMPING
	
	# Modify platform drop-through check
	if Input.is_action_pressed("ui_down") and is_on_floor() and can_drop_through:
		if has_platform_below():
			drop_through_platform()

func handle_walking_state(delta):
	# Only allow walking state when on floor
	if not is_on_floor():
		current_state = State.IDLE
		return
	
	# Check for click movement first
	if Input.is_action_just_pressed("click"):
		print("Click detected in walking state")
		var clicked_pos = get_global_mouse_position()
		target_position = get_walkable_position(clicked_pos)
		print("Target position set to: ", target_position)
		current_state = State.MOVING_TO_TARGET
		return
	
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		if will_fall_off_edge(direction):
			velocity.x = 0
		else:
			last_direction = sign(direction)
			sprite.flip_h = last_direction < 0
			velocity.x = direction * SPEED
	else:
		velocity.x = 0
	
	if Input.is_action_just_pressed("shoot"):
		velocity.x = 0
		handle_shoot()
		return
	elif Input.is_action_pressed("ui_accept") and has_platform_above():
		current_state = State.JUMPING
		return
	
	animation_player.play("walk")
	
	if direction == 0:
		current_state = State.IDLE

func will_fall_off_edge(direction: float) -> bool:
	var space_state = get_world_2d().direct_space_state
	var check_position = global_position + Vector2(direction * 10, -5)
	
	var params = PhysicsRayQueryParameters2D.create(
		check_position,
		check_position + Vector2(0, 10),
		1
	)
	
	var result = space_state.intersect_ray(params)
	return result.is_empty()

func handle_jumping_state(delta):
	velocity.y = JUMP_VELOCITY
	velocity.x = 0  # Remove horizontal momentum for more controlled vertical jumps
	
	animation_player.play("jump")
	current_state = State.IDLE  # Allow for other inputs while in air

func handle_moving_to_target_state(delta):
	# Allow interruption with new clicks or shooting
	if Input.is_action_just_pressed("shoot"):
		target_position = null  # Clear the target
		handle_shoot()
		return
	elif Input.is_action_just_pressed("click"):
		print("New click in moving state")
		var clicked_pos = get_global_mouse_position()
		target_position = get_walkable_position(clicked_pos)
		print("New target position: ", target_position)
	
	if target_position:
		print("Moving to target: ", target_position, " current pos: ", position)
		var direction_to_target = position.direction_to(target_position)
		var distance_to_target = position.distance_to(target_position)
		
		if distance_to_target > 10:
			if direction_to_target.x != 0:  # Only update when actually moving
				last_direction = sign(direction_to_target.x)
				sprite.flip_h = last_direction < 0
				
				# The issue is here - we're immediately canceling movement and clearing target
				# when there's an edge, instead of letting the player stop at the edge
				velocity.x = direction_to_target.x * SPEED
				if will_fall_off_edge(sign(direction_to_target.x)):
					print("Edge detected, stopping")
					velocity.x = 0
				animation_player.play("walk")
		else:
			target_position = null
			current_state = State.IDLE

func handle_shooting_state(delta):
	if is_on_floor():
		velocity.x = 0
	animation_player.play("shoot")
	# Wait for animation to finish
	await animation_player.animation_finished
	
	# Check if we should keep shooting
	if Input.is_action_pressed("shoot"):
		current_state = State.SHOOTING  # Start another shot
	else:
		current_state = State.IDLE

func drop_through_platform():
	# Temporarily disable collision with one-way platforms
	set_collision_mask_value(1, false)  # Adjust mask value based on your collision layer setup
	can_drop_through = false
	
	# Create a timer to re-enable collision
	var timer = get_tree().create_timer(DROP_THROUGH_DURATION)
	timer.timeout.connect(func():
		set_collision_mask_value(1, true)
		can_drop_through = true
	)

func has_platform_below() -> bool:
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsRayQueryParameters2D.create(
		global_position,  # Start from current position
		global_position + Vector2(0, DROP_CHECK_DISTANCE),  # Check downward
		1  # Ground layer
	)
	
	var results = space_state.intersect_ray(params)
	if results and results.position.y > global_position.y + 10:  # Add small offset to avoid detecting current platform
		return true
	return false

func has_platform_above() -> bool:
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsRayQueryParameters2D.create(
		global_position,  # Start from current position
		global_position + Vector2(0, -JUMP_CHECK_DISTANCE),  # Check upward
		1  # Ground layer
	)
	
	var results = space_state.intersect_ray(params)
	if results and results.position.y < global_position.y - 10:  # Add small offset
		return true
	return false

func handle_shoot():
	current_state = State.SHOOTING

func _draw():
	if OS.is_debug_build():
		draw_line(Vector2.ZERO, Vector2(0, DROP_CHECK_DISTANCE), Color.RED)
		var check_pos = Vector2(10, -5)  # Right check, synced with raycast
		var check_down = Vector2(0, 10)  # Down check, synced with raycast
		draw_line(check_pos, check_pos + check_down, Color.GREEN)
		check_pos = Vector2(-10, -5)  # Left check
		draw_line(check_pos, check_pos + check_down, Color.GREEN)
