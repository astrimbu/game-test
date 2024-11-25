class_name WalkingState
extends PlayerState

func enter_state(player: CharacterBody2D) -> void:
	player.animation_player.play("walk")

func update_state(player: CharacterBody2D, delta: float) -> void:
	apply_gravity(player, delta)
	
	if not player.is_on_floor():
		player.set_state("idle")
		return
	
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		if player.will_fall_off_edge(direction):
			player.velocity.x = 0
		else:
			if direction != player.last_direction:
				player.last_direction = direction
				player.scale.x = -1
			player.velocity.x = direction * player.SPEED
	else:
		player.velocity.x = 0
		player.set_state("idle")
		return
	
	if Input.is_action_pressed("ui_up") and player.has_platform_above():
		player.set_state("jumping")
		return
	
	player.move_and_slide()

func handle_input(player: CharacterBody2D, event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		handle_click(player, player.get_global_mouse_position())
	elif event.is_action_pressed("shoot"):
		player.velocity.x = 0
		player.set_state("shooting") 