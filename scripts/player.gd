extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -350.0
const DROP_THROUGH_DURATION = 0.2
const DROP_CHECK_DISTANCE = 400  # Maximum distance to check for platforms below
const JUMP_CHECK_DISTANCE = 100  # Distance to check for platforms above
const RAY_ANGLES = [0, 15, 30, 45, 60]  # Angles in degrees to check
const RAY_LENGTH = 200  # Length of rays to cast
const JUMP_POSITION_TOLERANCE = 20  # How close we need to be to jump
const INTERACTION_DISTANCE = 86.0

var target_position = null
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var ray_length = 50
var can_drop_through = true
var last_direction = 1  # 1 for right, -1 for left
var is_shooting = false
var intermediate_target = null  # The next platform to jump to
var platform_jump_position = null  # The position to jump from
var target_enemy = null
var target_npc = null

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var target_indicator = $"../TargetIndicator"
@onready var resources = PlayerResources.new()

# Define states
# enum State { IDLE, WALKING, JUMPING, MOVING_TO_TARGET, SHOOTING }
var current_state: PlayerState = null
var states: Dictionary = {}

func _ready():
	add_to_group("player")
	add_child(resources)
	
	# Initialize states
	states = {
		"idle": IdleState.new(),
		"walking": WalkingState.new(),
		"jumping": JumpingState.new(),
		"moving_to_target": MovingToTargetState.new(),
		"shooting": ShootingState.new()
	}
	
	# Start in idle state
	set_state("idle")

func set_state(new_state_name: String) -> void:
	if current_state:
		current_state.exit_state(self)
	
	current_state = states[new_state_name]
	current_state.enter_state(self)

func _physics_process(delta: float) -> void:
	# Update target indicator position if we have a target enemy
	if target_enemy and target_indicator.visible:
		target_indicator.global_position = target_enemy.global_position - Vector2(0, target_enemy.indicator_offset)
	
	if current_state:
		current_state.update_state(self, delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(self, event)

func get_walkable_position(clicked_pos: Vector2) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	
	# First try a direct ray at the click position
	var params = PhysicsRayQueryParameters2D.create(
		clicked_pos + Vector2(0, -20),  # Start just slightly above click
		clicked_pos + Vector2(0, 20),   # End just slightly below click
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

func handle_click(clicked_pos: Vector2):
	# Don't interrupt if we're in the middle of a manual shooting animation
	if is_shooting and not target_enemy:
		return
	
	# First check if we clicked on something interactive
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = clicked_pos
	params.collision_mask = 0b100 | 0b1000  # Layer 3 (Enemy) and Layer 4 (NPC)
	params.collide_with_bodies = true
	
	var results = space_state.intersect_point(params)
	
	# Clear previous target and indicator first
	target_enemy = null
	target_indicator.visible = false
	
	if not results.is_empty():
		var clicked_object = results[0].collider
		
		if clicked_object is CharacterBody2D:  # Base class for both Enemy and NPC
			if clicked_object.get_collision_layer_value(4):  # NPC check
				target_npc = clicked_object
				
				# Check if we're already on the same height level (with small tolerance)
				var height_difference = abs(clicked_object.global_position.y - global_position.y)
				var direction = sign(clicked_object.global_position.x - global_position.x)

				if height_difference <= 10:
					# On same level - calculate position that maintains interaction distance
					target_position = clicked_object.global_position - Vector2(direction * INTERACTION_DISTANCE, 0)
				else:
					# Different height - walk to NPC's position
					target_position = get_walkable_position(clicked_object.global_position - Vector2(direction * 50, 0))
				
				# Update target indicator above NPC's head
				target_indicator.visible = true
				target_indicator.global_position = clicked_object.global_position - Vector2(0, clicked_object.indicator_offset)

				set_state("moving_to_target")
				return
			elif clicked_object.get_collision_layer_value(3):  # Enemy check
				# Prevent spam clicking
				if is_shooting:
					set_state("idle")
					return

				target_enemy = clicked_object
				target_indicator.visible = true
				target_indicator.global_position = clicked_object.global_position - Vector2(0, clicked_object.indicator_offset)
				
				target_position = get_walkable_position(clicked_object.global_position)
				set_state("moving_to_target")
				return
	
	# If no interactive object was clicked, handle as normal movement
	target_position = get_walkable_position(clicked_pos)
	target_indicator.visible = true
	target_indicator.global_position = target_position
	set_state("moving_to_target")

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

func can_reach_with_jump(target_y: float) -> bool:
	# Calculate maximum height reached with jump
	# Not entirely accurate, but close enough for now
	# Using physics formula: h = v0*t + (1/2)*a*t^2
	# At peak height, v = 0, so: 0 = v0 + a*t
	# Therefore t = -v0/a
	var time_to_peak = -JUMP_VELOCITY / gravity
	var max_jump_height = JUMP_VELOCITY * time_to_peak + 0.5 * gravity * time_to_peak * time_to_peak
	
	# Check if target is within reachable height
	return position.y + max_jump_height <= target_y

func find_next_platform() -> Dictionary:
	var space_state = get_world_2d().direct_space_state
	var best_platform = null
	var best_distance = INF
	var best_jump_position = null
	
	# Convert angles to radians and check both left and right
	for angle_deg in RAY_ANGLES:
		for direction in [-1, 1]:
			var angle = deg_to_rad(angle_deg) * direction
			var ray_end = Vector2(
				cos(angle) * RAY_LENGTH,
				-sin(angle) * RAY_LENGTH
			)
			
			var params = PhysicsRayQueryParameters2D.create(
				global_position,
				global_position + ray_end,
				1  # Ground layer
			)
			
			var result = space_state.intersect_ray(params)
			if result and result.position.y < position.y - 10:  # Platform is above us
				if can_reach_with_jump(result.position.y):
					# Calculate jump position (slightly before the edge if needed)
					var jump_x = result.position.x - (direction * 10)
					var jump_position = Vector2(jump_x, position.y)
					
					# Check if this platform is closer to our target
					var dist_to_target = result.position.distance_to(target_position)
					if dist_to_target < best_distance:
						best_distance = dist_to_target
						best_platform = result.position
						best_jump_position = jump_position
	
	return {
		"platform": best_platform,
		"jump_position": best_jump_position
	}

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

func set_target_enemy(enemy):
	target_enemy = enemy
	if not enemy:
		target_indicator.visible = false
		return
	
	# Update target indicator
	target_indicator.visible = true
	target_indicator.global_position = enemy.global_position - Vector2(0, enemy.indicator_offset)
	
	# Get enemy platform position
	var platform_position = get_walkable_position(enemy.global_position)
	
	# Always move to enemy platform first
	target_position = platform_position
	set_state("moving_to_target")

func shoot(is_auto: bool = false):
	# Check for click interruption first
	if Input.is_action_just_pressed("click"):
		handle_click(get_global_mouse_position())
		return
	
	if is_shooting:
		return
	
	current_state = states["shooting"]
	is_shooting = true
	animation_player.play("shoot")
	queue_redraw()
	
	# Add delay to match animation
	await get_tree().create_timer(0.2).timeout
	
	# Check again if target was cleared during the delay
	if target_enemy == null and is_auto:
		is_shooting = false
		set_state("idle")
		animation_player.play("idle")
		return
	
	# Calculate shoot position offset from center (30 pixels up)
	var shoot_position = global_position + Vector2(0, -60)
	
	# Create a raycast in the direction the player is facing
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		shoot_position,
		shoot_position + Vector2(last_direction * 1000, 0)  # 1000 pixels range
	)
	query.collision_mask = 0b100  # Layer 3 (Enemy)
	var result = space_state.intersect_ray(query)
	
	if result:
		var enemy = result.collider
		if enemy.has_method("hit"):
			enemy.hit(shoot_position)
			if enemy.is_dead:
				target_enemy = null
				target_position = null
				target_indicator.visible = false

	# Wait for animation to complete
	await animation_player.animation_finished
	
	is_shooting = false
	if (is_auto and target_enemy) or (not is_auto and Input.is_action_pressed("ui_accept")):
		# For manual shooting, immediately start next shot if spacebar still held
		if not is_auto:
			shoot(false)
		# For auto shooting, add a small delay between shots
		else:
			await get_tree().create_timer(0.1).timeout
			if target_enemy:  # Check if target still exists after delay
				shoot(true)
	else:
		set_state("idle")
		animation_player.play("idle")
	queue_redraw()

#func _draw():
	#if OS.is_debug_build():
		# Edge detection raycasts
		#for angle_deg in RAY_ANGLES:
			#for direction in [-1, 1]:
				#var angle = deg_to_rad(angle_deg) * direction
				#var ray_end = Vector2(
					#cos(angle) * RAY_LENGTH,
					#-sin(angle) * RAY_LENGTH
				#)
				#draw_line(Vector2.ZERO, ray_end, Color(1, 1, 0, 0.2))
		# if is_shooting:
		# 	var shoot_start = Vector2(35, -55)
		# 	var shoot_end = shoot_start + Vector2(1000, 0)
		# 	draw_line(shoot_start, shoot_end, Color(1, 0, 0, .8), 2.0)
