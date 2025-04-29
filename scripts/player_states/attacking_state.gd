class_name AttackingState
extends PlayerState

# Removed hardcoded constants, range is determined in PlayerCombat
# const PUNCH_RANGE = 15.0 
# const CHASE_THRESHOLD = 20.0 

# How much further than attack range the enemy must move before we chase
const CHASE_THRESHOLD_MULTIPLIER = 1.5 

# COMBAT ANIMATION LIFECYCLE:
# 1. Animation starts playing
# 2. Damage is applied at a specific frame (damage_apply_timer)
# 3. Animation continues to completion (animation_complete_timer)
# 4. Cooldown begins for next attack (attack_timer)
#
# IMPORTANT: State transitions must respect this full lifecycle to prevent
# animations from being cut short or combat mechanics being interrupted.

func enter_state(player: CharacterBody2D) -> void:
	print("Enter AttackingState")
	if not is_instance_valid(player.target_enemy) or player.target_enemy.get_is_dead():
		print("WARN: Entering AttackingState with invalid target. Idling.")
		player.request_state_change("idle")
		return
	
	# Stop movement and face enemy
	player.velocity.x = 0 # Ensure velocity is zeroed
	player.movement.move(0) # Apply friction/stop
	# Face the enemy immediately
	var enemy_direction = sign(player.target_enemy.global_position.x - player.global_position.x)
	if enemy_direction != 0:
		player.movement.set_facing_direction(enemy_direction)
	
	# Initiate the *first* attack (start_attacking handles timer/animation)
	print("AttackingState: Initiating first attack.")
	player.combat.start_attacking(player.target_enemy)

func update_state(player: CharacterBody2D, delta: float) -> void:
	apply_gravity(player, delta)
	
	# Always keep player stationary horizontally in this state
	player.velocity.x = 0
	player.move_and_slide()

	# --- Check Target Validity and State Transitions ---
	
	# MODIFIED CHECK:
	# Only transition out due to invalid target IF the combat component
	# is NOT actively in the middle of an attack animation cycle.
	if not is_instance_valid(player.target_enemy):
		if not player.combat.is_attacking:
			print("AttackingState: Target invalid AND attack anim finished. Idling.")
			player.request_state_change("idle")
			return
		else:
			# Target is invalid, but animation is still playing.
			# Do nothing here, let PlayerCombat finish the animation.
			# PlayerCombat._on_animation_complete will handle stopping combat
			# and emitting the signal that Player uses to finally go idle.
			print("AttackingState: Target invalid, but waiting for attack anim to finish...") # DEBUG
			return # Keep processing gravity/movement
		
	# Target is valid, keep facing the enemy
	var enemy_dir = sign(player.target_enemy.global_position.x - player.global_position.x)
	if enemy_dir != 0:
		player.movement.set_facing_direction(enemy_dir)

	# --- Wait for Combat Component to Signal Completion --- 
	# PlayerCombat now manages the timers and signals when an attack cycle
	# (including full animation) is truly complete or stopped.
	# AttackingState just needs to wait for Player to be transitioned
	# out by signals handled in player.gd (_on_combat_animation_ended or _on_enemy_killed)
	# or if the player initiates a new action via input.
	
	# Removed timer checks here, they are handled by PlayerCombat and Player signal connections.

	# Check if enemy moved out of range *after* an attack cycle completes?
	# This check needs rethinking. Maybe PlayerCombat should emit a different signal?
	# For now, rely on the player clicking again if enemy moves away.

	# print("AttackingState: Update loop finished, waiting for signals or input.") # DEBUG

func exit_state(player: CharacterBody2D) -> void:
	print("Exit AttackingState")
	# Crucial: Ensure the combat loop is stopped if we exit this state for any reason
	player.combat.stop_attacking()

func handle_input(player: CharacterBody2D, event: InputEvent) -> void:
	# Only block inputs during the critical damage application phase
	# This prevents interrupting the attack at important moments while still
	# allowing the player to queue up their next action
	if not player.combat.damage_apply_timer.is_stopped():
		return
	
	# Allow input handling if damage timer is stopped (i.e., during cooldown or between attacks)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			player.handle_mouse_down(event.position)
		else: # Released
			player.handle_mouse_up(event.position)
	# OLD Logic:
	# if player.is_attacking:
	# 	...
	# 	return 
	# 	
	# # --- Allow new click actions ONLY if attack cycle is finished (is_attacking is false) --- 
	# if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
	# 	...
	# 	player.handle_mouse_up(event.position) 