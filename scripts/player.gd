extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var target_position = null
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var ray_length = 100

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

# Define states
enum State { IDLE, WALKING, JUMPING, MOVING_TO_TARGET }
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
	
	# Apply movement last
	move_and_slide()

func handle_idle_state(delta):
	velocity.x = move_toward(velocity.x, 0, SPEED)
	animation_player.play("idle")
	
	if Input.get_axis("ui_left", "ui_right") != 0:
		current_state = State.WALKING
	elif Input.is_action_just_pressed("click"):
		var clicked_pos = get_global_mouse_position()
		var walkable_pos = get_walkable_position(clicked_pos)
		target_position = walkable_pos
		current_state = State.MOVING_TO_TARGET
	elif Input.is_action_just_pressed("ui_accept") and is_on_floor():
		current_state = State.JUMPING

func handle_walking_state(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED
	animation_player.play("walk")
	sprite.flip_h = direction < 0
	
	if direction == 0:
		current_state = State.IDLE
	elif Input.is_action_just_pressed("ui_accept") and is_on_floor():
		current_state = State.JUMPING

func handle_jumping_state(delta):
	velocity.y = JUMP_VELOCITY
	animation_player.play("jump")  # If you have a jump animation
	current_state = State.IDLE  # Allow for other inputs while in air

func handle_moving_to_target_state(delta):
	# Allow interruption with new clicks
	if Input.is_action_just_pressed("click"):
		var clicked_pos = get_global_mouse_position()
		target_position = get_walkable_position(clicked_pos)
	
	if target_position:
		var direction_to_target = position.direction_to(target_position)
		var distance_to_target = position.distance_to(target_position)
		
		if distance_to_target > 10:
			velocity.x = direction_to_target.x * SPEED
			animation_player.play("walk")
			sprite.flip_h = direction_to_target.x < 0
			
			# Allow jumping while moving to target
			if Input.is_action_just_pressed("ui_accept") and is_on_floor():
				current_state = State.JUMPING
				return
		else:
			target_position = null
			current_state = State.IDLE
