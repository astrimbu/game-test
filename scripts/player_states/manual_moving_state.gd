class_name ManualMovingState
extends PlayerState

func enter_state(player: CharacterBody2D) -> void:
	print("Enter ManualMovingState")
	if not player.is_attacking: # Should not be attacking
		player.animation_player.play("walk")

func update_state(player: CharacterBody2D, delta: float) -> void:
	apply_gravity(player, delta)

	# Get keyboard input
	var direction = Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		player.movement.move(direction)
	else:
		# If no direction input, transition back to idle
		player.movement.move(0) # Stop movement
		player.request_state_change("idle")
		# move_and_slide will be called after state change in idle or by player itself? Let's call it here to apply stop.
		player.move_and_slide() 
		return # Exit early as we are changing state

	# Check for jump input (optional, could be its own state or handled here)
	if Input.is_action_just_pressed("ui_up") and player.is_on_floor():
		# TODO: Implement jump logic or transition to JumpingState
		player.movement.jump() # Assuming jump just applies velocity change

	# Check for drop through (optional)
	if Input.is_action_pressed("ui_down") and player.is_on_floor():
		if player.has_platform_below() and player.can_drop_through:
			player.drop_through_platform()

	# Apply movement
	player.move_and_slide()

func exit_state(player: CharacterBody2D) -> void:
	print("Exit ManualMovingState")
	player.movement.move(0) # Ensure movement stops fully if exiting for other reasons

# No handle_input needed here as movement is checked in update_state 