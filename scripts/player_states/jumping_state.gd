class_name JumpingState
extends PlayerState

func enter_state(player: CharacterBody2D) -> void:
	player.velocity.y = player.JUMP_VELOCITY
	player.velocity.x = 0  # Keep vertical-only jump
	player.animation_player.play("jump")

func update_state(player: CharacterBody2D, delta: float) -> void:
	apply_gravity(player, delta)
	
	# Apply movement
	player.move_and_slide()
	
	# Check if we've landed
	if player.is_on_floor():
		if player.target_position:
			player.set_state("moving_to_target")
		else:
			player.set_state("idle")

func handle_input(player: CharacterBody2D, event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		handle_click(player, player.get_global_mouse_position())
	elif event.is_action_pressed("shoot"):
		player.set_state("shooting") 