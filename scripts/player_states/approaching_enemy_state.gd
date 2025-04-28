class_name ApproachingEnemyState
extends PlayerState

# TODO: Get punch range from config or player/interaction component
# const PUNCH_RANGE = 15.0 # Removed, using dynamic range
const HORIZONTAL_THRESHOLD = 5.0 # How close horizontally before stopping x-movement

func enter_state(player: CharacterBody2D) -> void:
	print("Enter ApproachingEnemyState")
	if not is_instance_valid(player.target_enemy) or player.target_enemy.get_is_dead():
		player.request_state_change("idle")
		return
	player.animation_player.play("walk")
	# Ensure target indicator is visible for the enemy
	player._update_target_indicator(player.target_enemy.global_position - Vector2(0, player.target_enemy.indicator_offset))

func update_state(player: CharacterBody2D, delta: float) -> void:
	if not is_instance_valid(player.target_enemy) or player.target_enemy.get_is_dead():
		player.request_state_change("idle")
		return

	apply_gravity(player, delta)

	# Recalculate target position each frame to follow moving enemy
	var target_pos = player.interaction.get_walkable_position(player.target_enemy.global_position)
	
	# If walkable position is invalid, maybe stop and idle?
	if target_pos == Vector2.ZERO:
		print("WARN: Cannot find walkable path to enemy, idling.")
		player.movement.move(0) # Stop horizontal movement
		player.move_and_slide() 
		player.request_state_change("idle")
		return

	# Check distance to the enemy itself (not the walkable position) for attack range
	var distance_to_enemy = player.global_position.distance_to(player.target_enemy.global_position)
	var current_attack_range = player.combat.get_current_attack_range()

	# Check if close enough to attack (and roughly same height?)
	var height_difference = abs(player.global_position.y - player.target_enemy.global_position.y)
	# Use a config value for vertical tolerance?
	if distance_to_enemy <= current_attack_range and height_difference < player.config.VERTICAL_TOLERANCE: 
		player.movement.move(0) # Stop horizontal movement
		player.move_and_slide() # Apply stop and gravity
		player.request_state_change("attacking")
		return

	# Move towards the calculated walkable position
	var direction = sign(target_pos.x - player.position.x)
	if abs(target_pos.x - player.position.x) > HORIZONTAL_THRESHOLD: 
		player.movement.move(direction)
	else:
		player.movement.move(0) # Stop horizontal if close enough

	# Handle jumping/falling logic (similar to old MovingToTargetState or new MovingState)
	# TODO: Add jump/fall logic if needed for approaching enemies across gaps/platforms
	
	# Need to flip sprite based on movement direction or enemy position?
	# REMOVED direct sprite flipping - handled by PlayerMovement.move()
	# if direction != 0:
	# 	player.sprite.flip_h = (direction < 0)
	# elif is_instance_valid(player.target_enemy): # Face enemy if standing still
	# 	player.sprite.flip_h = (player.target_enemy.global_position.x < player.global_position.x)


	player.move_and_slide()

func exit_state(player: CharacterBody2D) -> void:
	print("Exit ApproachingEnemyState")
	player.movement.move(0) # Ensure movement stops
	# Don't clear target_enemy here, AttackingState needs it

func handle_input(player: CharacterBody2D, event: InputEvent) -> void:
	# Allow new click actions to interrupt approaching
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		player.handle_mouse_down(event.position) # Let interaction check for item pickup
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		player.handle_mouse_up(event.position) # Let interaction emit new intent

	# Allow manual movement override? (Optional)
	# var direction = Input.get_axis("move_left", "move_right")
	# if direction != 0:
	#    player.request_state_change("moving") # Or a dedicated manual walking state? 