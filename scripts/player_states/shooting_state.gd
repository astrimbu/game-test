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

func exit_state(player: CharacterBody2D) -> void:
	# Make sure we clean up shooting state when interrupted
	player.is_shooting = false
	player.animation_player.play("idle")
