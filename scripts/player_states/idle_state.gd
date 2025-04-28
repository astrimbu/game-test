class_name IdleState
extends PlayerState

func enter_state(player: CharacterBody2D) -> void:
	if not player.is_attacking:
		player.animation_player.play("idle")
	player.velocity.x = 0

func update_state(player: CharacterBody2D, delta: float) -> void:
	apply_gravity(player, delta)
	
	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0, player.config.SPEED)
		
		# Check for movement input
		if Input.get_axis("ui_left", "ui_right") != 0:
			player.request_state_change("manual_moving")
			return
			
		# Check for jump input
		if Input.is_action_pressed("ui_up") and player.has_platform_above():
			player.request_state_change("jumping")
			return
			
		# Check for drop through
		if Input.is_action_pressed("ui_down") and player.can_drop_through:
			if player.has_platform_below():
				player.drop_through_platform()
	
	# Apply movement
	player.move_and_slide()

# Add input handler for clicks (optional, could be handled by player._unhandled_input)
# func handle_input(player: CharacterBody2D, event: InputEvent) -> void:
# 	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
# 		player.handle_mouse_down(event.position)
# 	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
# 		player.handle_mouse_up(event.position)
