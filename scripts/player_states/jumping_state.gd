class_name JumpingState
extends PlayerState

func enter_state(player: CharacterBody2D) -> void:
	player.velocity.x = 0  # Reset horizontal velocity
	player.velocity.y = player.config.JUMP_VELOCITY
	player.animation_player.play("jump")

func update_state(player: CharacterBody2D, delta: float) -> void:
	apply_gravity(player, delta)
	
	# Keep x velocity at 0
	player.velocity.x = 0
	
	player.move_and_slide()
	
	# Check if we've landed
	if player.is_on_floor():
		# Player._unhandled_input will likely handle clicks that happened mid-air
		# Check if player has a move target destination (set via click before/during jump)
		if player.interaction.target_position != Vector2.ZERO:
			player.request_state_change("moving")
		# Check if movement keys are held upon landing
		elif Input.get_axis("ui_left", "ui_right") != 0:
			player.request_state_change("moving")
		else:
			player.request_state_change("idle")