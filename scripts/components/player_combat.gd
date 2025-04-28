class_name PlayerCombat
extends Node

@export var config: PlayerConfig
@export var combat_config: CombatConfig
@export var character: CharacterBody2D
@export var animation_player: AnimationPlayer

var is_attacking := false
var target_enemy: CharacterBody2D = null
var attack_timer: Timer = null # Timer for cooldown *between* attacks
var damage_apply_timer: Timer = null # Timer for delay *within* an attack before damage hits
var auto_combat_enabled := false
var initial_attack_delay := 0.2  # Delay for the first attack - TODO: Use this?

# Current attack properties (set in start_attacking)
var current_attack_style: String = ""
var current_attack_range: float = 0.0
var current_attack_cooldown: float = 1.0 # Default fallback
var current_attack_animation: String = ""
# Add a property to store the current damage delay
var current_damage_delay: float = 0.0
# Add property to track animation duration
var current_animation_duration: float = 0.0
var animation_complete_timer: Timer = null

func _ready() -> void:
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	# attack_timer is now used to START the next attack animation after cooldown
	attack_timer.connect("timeout", Callable(self, "_on_attack_cooldown_finished"))
	add_child(attack_timer)

	damage_apply_timer = Timer.new()
	damage_apply_timer.one_shot = true
	damage_apply_timer.connect("timeout", Callable(self, "_on_damage_apply_timer_timeout"))
	add_child(damage_apply_timer)
	
	animation_complete_timer = Timer.new()
	animation_complete_timer.one_shot = true
	animation_complete_timer.connect("timeout", Callable(self, "_on_animation_complete"))
	add_child(animation_complete_timer)
	
	# Listen for enemy death
	EventBus.enemy_killed.connect(_on_enemy_killed)

func _on_attack_cooldown_finished() -> void:
	# Cooldown is finished, time to start the next attack *if* still auto-attacking
	print("Combat: Attack cooldown finished.")
	if auto_combat_enabled and is_instance_valid(target_enemy) and not target_enemy.get_is_dead():
		print("Combat: Looping attack, starting next animation and damage timer.")
		is_attacking = true # Indicate we are in the attack animation phase
		EventBus.combat_animation_started.emit(current_attack_animation)
		animation_player.play(current_attack_animation)
		damage_apply_timer.start(current_damage_delay) # Start timer for damage application
		# Start timer for animation completion
		animation_complete_timer.start(current_animation_duration)
	else:
		# If conditions not met, ensure we stop cleanly
		print("Combat: Attack loop condition not met on cooldown finish, stopping.")
		stop_attacking()

func _on_damage_apply_timer_timeout() -> void:
	# Damage timer finished, apply the damage if target is still valid
	print("Combat: Damage apply timer timeout.")
	if not is_instance_valid(target_enemy):
		print("Combat: Target invalid on damage timer timeout.")
		return
		
	if target_enemy.get_is_dead():
		print("Combat: Target died before damage applied.")
		return

	# --- Perform the attack damage/action based on style ---
	print("Combat: Applying damage with style: %s" % current_attack_style)
	if current_attack_style == "unarmed" or current_attack_style == "melee":
		var damage = get_total_damage()
		target_enemy.take_damage(damage)
		EventBus.publish_damage_dealt(damage, target_enemy)
		print("Combat: Applied %d melee/unarmed damage to %s" % [damage, target_enemy.name])
	elif current_attack_style == "ranged":
		# TODO: Implement projectile spawning
	
		var damage = get_total_damage()
		target_enemy.take_damage(damage)
		EventBus.publish_damage_dealt(damage, target_enemy)
	elif current_attack_style == "magic":
		print("Combat: Magic attack - Placeholder.")
	else:
		printerr("Combat: Unknown attack style: ", current_attack_style)
	# -----------------------------------------------------

	# Damage applied. Now start the cooldown timer for the *next* attack.
	# The cooldown runs *after* the damage point.
	if auto_combat_enabled and is_instance_valid(target_enemy) and not target_enemy.get_is_dead():
		# Start the FULL cooldown timer now.
		print("Combat: Damage applied. Starting FULL cooldown timer for %.2f seconds." % current_attack_cooldown)
		attack_timer.start(current_attack_cooldown)

func _on_animation_complete() -> void:
	print("Combat: Attack animation complete.")
	if not auto_combat_enabled or (is_instance_valid(target_enemy) and target_enemy.get_is_dead()):
		stop_attacking()

func _on_enemy_killed(enemy: BaseEnemy) -> void:
	# Check if the killed enemy was our current target
	if enemy == target_enemy:
		print("Combat: Target enemy killed. Allowing animation to complete.")
		# Prevent the loop from continuing after the current cooldown finishes
		auto_combat_enabled = false 
		# Stop attack timer to prevent starting new attacks
		attack_timer.stop()
		# Let the current animation finish via animation_complete_timer

func start_attacking(target: CharacterBody2D) -> void:
	if not is_instance_valid(target) or target.get_is_dead():
		print("Combat: Cannot start attacking invalid target.")
		return
	
	# --- Determine Attack Properties ---
	var weapon = GameState.player_data.equipment.get("weapon")
	if weapon and weapon is ItemData and weapon.stats:
		print("Combat: Using weapon stats: ", weapon.name)
		current_attack_style = weapon.stats.get("attack_style", combat_config.unarmed_attack_style)
		current_attack_range = weapon.stats.get("range", combat_config.unarmed_attack_range)
		current_attack_cooldown = weapon.stats.get("cooldown", combat_config.unarmed_attack_cooldown)
		current_attack_animation = weapon.stats.get("animation", combat_config.unarmed_attack_animation)
		current_damage_delay = weapon.stats.get("damage_delay", combat_config.unarmed_damage_delay)
		current_animation_duration = weapon.stats.get("animation_duration", combat_config.unarmed_animation_duration)
	else:
		print("Combat: Using unarmed stats")
		current_attack_style = combat_config.unarmed_attack_style
		current_attack_range = combat_config.unarmed_attack_range
		current_attack_cooldown = combat_config.unarmed_attack_cooldown
		current_attack_animation = combat_config.unarmed_attack_animation
		current_damage_delay = combat_config.unarmed_damage_delay
		current_animation_duration = combat_config.unarmed_animation_duration
	# ----------------------------------
		
	print("Combat: Starting attacking loop for %s with style \'%s\' (Range: %s, Cooldown: %s, Anim: %s, DmgDelay: %s, Duration: %s)" % [target.name, current_attack_style, current_attack_range, current_attack_cooldown, current_attack_animation, current_damage_delay, current_animation_duration])
	auto_combat_enabled = true
	target_enemy = target
	
	# Start the first attack immediately
	if not is_attacking:
		print("Combat: Starting first attack sequence.")
		is_attacking = true
		EventBus.combat_animation_started.emit(current_attack_animation)
		animation_player.play(current_attack_animation)
		# Start timer for the damage application point of the *first* attack
		damage_apply_timer.start(current_damage_delay)
		# Start timer for animation completion
		animation_complete_timer.start(current_animation_duration)

func stop_attacking() -> void:
	# Only print/emit if we were actually attacking
	if auto_combat_enabled or is_attacking:
		print("Combat: Stopping attacking loop.")
		auto_combat_enabled = false
		# Don't clear target_enemy here, Player/States manage the canonical target
		is_attacking = false
		attack_timer.stop()
		damage_apply_timer.stop()
		animation_complete_timer.stop()
		# Ensure animation stops using the *correct* animation name for this attack cycle
		if not current_attack_animation.is_empty():
			EventBus.combat_animation_ended.emit(current_attack_animation)
		else:
			EventBus.combat_animation_ended.emit("punch") # Fallback

		# Reset current attack properties
		current_attack_style = ""
		current_attack_range = 0.0
		current_attack_cooldown = 1.0
		current_attack_animation = ""
		current_damage_delay = 0.0
		current_animation_duration = 0.0

func take_damage(amount: int, source: Node) -> void:
	EventBus.publish_damage_taken(amount, source)
	# _enter_combat() # State handled by Player

func get_total_damage() -> int:
	var base = combat_config.base_damage
	
	# Add weapon damage if equipped
	var weapon = GameState.player_data.equipment.get("weapon")
	if weapon and weapon is ItemData and weapon.stats.has("damage"):
		base += weapon.stats.damage
	
	return base

# Returns the attack range based on the currently equipped weapon (or unarmed)
func get_current_attack_range() -> float:
	var weapon = GameState.player_data.equipment.get("weapon")
	if weapon and weapon is ItemData and weapon.stats:
		return weapon.stats.get("range", combat_config.unarmed_attack_range)
	else:
		return combat_config.unarmed_attack_range

func _enemies_in_range() -> bool:
	# Logic to check if any enemies are in combat range
	return target_enemy != null and is_instance_valid(target_enemy) and not target_enemy.get_is_dead()

func equip_weapon(weapon: ItemData) -> void:
	if weapon.equip_slot == "weapon":
		EventBus.publish_weapon_changed(weapon)
