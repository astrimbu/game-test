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

	# --- Ensure target is still valid conceptually --- 
	# We need a reference to the target for facing direction, 
	# but don't transition state based on death *yet*.
	if not is_instance_valid(player.target_enemy):
		print("AttackingState: Target became invalid (instance lost). Idling.")
		# Combat should already be stopped or stopping via PlayerCombat logic
		player.request_state_change("idle")
		return
		
	# Keep facing the enemy (even if they are dead, face the corpse briefly)
	var enemy_dir = sign(player.target_enemy.global_position.x - player.global_position.x)
	if enemy_dir != 0:
		player.movement.set_facing_direction(enemy_dir)

	# --- Timer Management ---
	# There are three critical timers that must complete:
	# 1. damage_apply_timer: Controls when in the animation damage is dealt
	# 2. attack_timer: Controls cooldown between attacks
	# 3. animation_complete_timer: Ensures full animation plays out
	var damage_timer_stopped = player.combat.damage_apply_timer.is_stopped()
	var attack_timer_stopped = player.combat.attack_timer.is_stopped()
	var animation_timer_stopped = player.combat.animation_complete_timer.is_stopped()

	# Don't interrupt the attack cycle if any timer is still running
	# This ensures animations complete even if the enemy dies mid-attack
	if not damage_timer_stopped or not attack_timer_stopped or not animation_timer_stopped:
		return
	
	# --- All timers are stopped --- 
	# A full attack cycle just completed.
	print("AttackingState: All timers stopped. Checking target status and range.") # DEBUG

	# Only check death status after all timers complete
	# This ensures the full animation plays even when killing an enemy
	if player.target_enemy.get_is_dead():
		print("AttackingState: Target is dead after attack cycle finished. Idling.")
		player.request_state_change("idle")
		return

	# Target is alive, check if it's still in range for the *next* attack.
	var distance = player.global_position.distance_to(player.target_enemy.global_position)
	var current_attack_range = player.combat.get_current_attack_range()
	var height_difference = abs(player.global_position.y - player.target_enemy.global_position.y)

	if distance > current_attack_range or height_difference >= player.config.VERTICAL_TOLERANCE:
		# Target is alive but now out of range.
		print("AttackingState: Target moved out of range after full attack cycle (Dist: %.1f, Range: %.1f). Approaching." % [distance, current_attack_range])
		player.request_state_change("approaching_enemy")
		return
	else:
		# Target is alive and still in range.
		# PlayerCombat._on_attack_cooldown_finished should handle starting the next attack.
		print("AttackingState: Still in range after full cycle. PlayerCombat will restart attack.") # DEBUG
		pass # Do nothing, wait for PlayerCombat's timer signal

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