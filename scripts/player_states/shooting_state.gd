class_name ShootingState
extends PlayerState

func enter_state(player: CharacterBody2D) -> void:
	if player.target_enemy and not player.target_enemy.get_is_dead():
		player.combat.start_auto_combat(player.target_enemy)

func update_state(player: CharacterBody2D, delta: float) -> void:
	apply_gravity(player, delta)
	
	if player.is_on_floor():
		player.velocity.x = 0
	
	player.move_and_slide()
	
	# Return to idle if no valid target
	if not player.target_enemy or player.target_enemy.get_is_dead():
		player.combat.stop_auto_combat()
		player.set_state("idle")

func exit_state(player: CharacterBody2D) -> void:
	player.combat.stop_auto_combat()
