class_name MovingState
extends PlayerState

const ARRIVAL_THRESHOLD = 5.0 # How close to target position to stop
const JUMP_HEIGHT_THRESHOLD = 10.0
const DROP_HEIGHT_THRESHOLD = 10.0

func enter_state(player: CharacterBody2D) -> void:
	print("Enter MovingState")
	# Check if target position is valid (set by Player intent handler)
	if player.interaction.target_position == Vector2.ZERO:
		print("WARN: Entering MovingState with ZERO target position. Idling.")
		player.request_state_change("idle")
		return
		
	if not player.is_attacking: # Should not be attacking in this state
		player.animation_player.play("walk")

func update_state(player: CharacterBody2D, delta: float) -> void:
	apply_gravity(player, delta)
	
	var target_pos = player.interaction.target_position
	
	# Check for invalid target position (e.g., if cleared unexpectedly)
	if target_pos == Vector2.ZERO:
		print("WARN: Target position became ZERO during MovingState. Idling.")
		player.movement.move(0) # Stop movement
		player.move_and_slide()
		player.request_state_change("idle")
		return

	# Check if we need to jump to reach the target
	if target_pos.y < player.position.y - JUMP_HEIGHT_THRESHOLD and player.is_on_floor():
		# Check if path is clear or if we should request jump state
		# Simple check for now: if target is significantly higher, try jumping
		# TODO: Add more sophisticated pathfinding or jump logic if needed
		player.request_state_change("jumping") 
		return 

	# Check if we need to drop through to reach the target
	if target_pos.y > player.position.y + DROP_HEIGHT_THRESHOLD and player.is_on_floor():
		if player.has_platform_below() and player.can_drop_through:
			player.drop_through_platform()

	# Move towards the target
	var current_pos = player.global_position
	var distance_to_target = current_pos.distance_to(target_pos)

	if distance_to_target > ARRIVAL_THRESHOLD:
		var direction_to_target = sign(target_pos.x - current_pos.x)
		player.movement.move(direction_to_target)
	else:
		# Reached the target position
		player.movement.move(0) # Stop movement
		player.move_and_slide() # Apply stop/gravity first
		print("Reached move target.")
		player.interaction.target_position = Vector2.ZERO # Clear target pos
		player.request_state_change("idle")
		return

	player.move_and_slide()

func exit_state(player: CharacterBody2D) -> void:
	print("Exit MovingState")
	player.movement.move(0) # Ensure movement stops
	# Don't clear target position here, might be needed by next state briefly
	# Or clear it if we are sure the arrival logic always handles it.
	# player.interaction.target_position = Vector2.ZERO 

func handle_input(player: CharacterBody2D, event: InputEvent) -> void:
	# Allow new click actions to interrupt movement
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		player.handle_mouse_down(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		player.handle_mouse_up(event.position)

	# Allow manual movement input to take over (optional)
	# var direction = Input.get_axis("move_left", "move_right")
	# if direction != 0:
	#    player.request_state_change("manual_walking") # Needs a dedicated state
