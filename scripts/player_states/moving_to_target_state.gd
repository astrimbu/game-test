class_name MovingToTargetState
extends PlayerState

func enter_state(player: CharacterBody2D) -> void:
	# Clear enemy target when entering moving state
	if not player.target_enemy or player.target_enemy.get_is_dead():
		player.combat.target_enemy = null
	
	if not player.is_shooting:
		player.animation_player.play("walk")

func update_state(player: CharacterBody2D, delta: float) -> void:
	apply_gravity(player, delta)
	
	if not player.target_position:
		player.interaction.clear_targets()
		player.set_state("idle")
		return
	
	# Check if we need to jump to reach the target
	if player.target_position.y < player.position.y - 10 and player.is_on_floor():
		if player.has_platform_above():
			player.set_state("jumping")
			return
	
	# Check if we need to drop through to reach the target
	if player.target_position.y > player.position.y + 10 and player.is_on_floor():
		if player.has_platform_below() and player.can_drop_through:
			player.drop_through_platform()
	
	# Move towards the target
	var direction_to_target = sign(player.target_position.x - player.position.x)
	var at_target_x = abs(player.position.x - player.target_position.x) <= 10
	var at_target_y = abs(player.position.y - player.target_position.y) <= 10
	
	if not (at_target_x and at_target_y):
		if not at_target_x:
			player.movement.move(direction_to_target)
			
			# Check if we can start shooting while moving
			if player.target_enemy and not player.target_enemy.is_dead:
				var height_difference = abs(player.target_enemy.global_position.y - player.global_position.y)
				if height_difference <= 10 and player.is_on_floor():
					player.set_state("shooting")
					return
		else:
			player.movement.move(0)
	else:
		player.movement.move(0)
		if player.is_on_floor():
			if player.target_enemy and not player.target_enemy.is_dead:
				var distance = player.global_position.distance_to(player.target_position)
				if distance <= 50:  # Attack range
					player.set_state("shooting")
					return
			elif player.target_npc and player.target_npc.can_interact:
				player.target_npc.start_interaction()
				player.interaction.clear_targets()
				player.set_state("idle")
			else:
				player.interaction.clear_targets()
				player.set_state("idle")
	
	player.move_and_slide()
