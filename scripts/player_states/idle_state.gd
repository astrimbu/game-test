class_name IdleState
extends PlayerState

func enter_state(player: CharacterBody2D) -> void:
	if not player.is_shooting:
		player.animation_player.play("idle")
	player.velocity.x = 0

func update_state(player: CharacterBody2D, delta: float) -> void:
	apply_gravity(player, delta)
	
	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
		
		# Check for movement input
		if Input.get_axis("ui_left", "ui_right") != 0:
			player.set_state("walking")
			return
			
		# Check for jump input
		if Input.is_action_pressed("ui_up") and player.has_platform_above():
			player.set_state("jumping")
			return
			
		# Check for drop through
		if Input.is_action_pressed("ui_down") and player.can_drop_through:
			if player.has_platform_below():
				player.drop_through_platform()
	
	# Apply movement
	player.move_and_slide()

func handle_input(player: CharacterBody2D, event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		handle_click(player, player.get_global_mouse_position())
	elif event.is_action_pressed("shoot"):
		player.set_state("shooting") 
