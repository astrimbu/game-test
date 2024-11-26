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
		if player.target_position:
			player.set_state("moving_to_target")
		elif Input.get_axis("ui_left", "ui_right") != 0:
			player.set_state("walking")
		else:
			player.set_state("idle")