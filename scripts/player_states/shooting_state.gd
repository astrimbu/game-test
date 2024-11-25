class_name ShootingState
extends PlayerState

func enter_state(player: CharacterBody2D) -> void:
	if not player.is_shooting:
		player.shoot(player.target_enemy != null)

func update_state(player: CharacterBody2D, delta: float) -> void:
	apply_gravity(player, delta)
	
	if player.is_on_floor():
		player.velocity.x = 0
	
	player.move_and_slide()
	
	# Return to idle if shooting is done and no auto-target
	if not player.is_shooting and not player.target_enemy:
		player.set_state("idle")

func handle_input(player: CharacterBody2D, event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		handle_click(player, player.get_global_mouse_position())
	elif event.is_action_pressed("shoot") and not player.is_shooting:
		player.shoot(player.target_enemy != null) 
