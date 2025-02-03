class_name PlayerCombat
extends Node

@export var config: PlayerConfig
@export var combat_config: CombatConfig
@export var character: CharacterBody2D
@export var animation_player: AnimationPlayer

var is_shooting := false
var target_enemy: CharacterBody2D = null
var shoot_timer: Timer = null
var current_combat_state: String = "idle"
var auto_combat_enabled := false
var attack_cooldown := 0.6  # Time between attacks
var initial_attack_delay := 0.2  # Delay for the first shot

func _ready() -> void:
	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	shoot_timer.connect("timeout", Callable(self, "_on_shoot_timer_timeout"))
	add_child(shoot_timer)
	
	# Listen for enemy death
	EventBus.enemy_killed.connect(_on_enemy_killed)
	
	# Listen for combat state changes
	EventBus.combat_state_changed.connect(_on_combat_state_changed)

func shoot(is_auto: bool = false) -> void:
	if is_shooting:
		return
	
	is_shooting = true
	_enter_combat()
	EventBus.combat_animation_started.emit("shoot")
	animation_player.play("shoot")
	shoot_timer.start(attack_cooldown)

func _enter_combat() -> void:
	if current_combat_state != "combat":
		current_combat_state = "combat"
		EventBus.publish_combat_state_change("combat")

func _exit_combat() -> void:
	if current_combat_state != "idle":
		current_combat_state = "idle"
		EventBus.publish_combat_state_change("idle")

func _on_shoot_timer_timeout() -> void:
	if not target_enemy:  # Target might have been cleared/died
		is_shooting = false
		EventBus.combat_animation_ended.emit("shoot")
		return
		
	if target_enemy.get_is_dead():
		is_shooting = false
		target_enemy = null
		EventBus.combat_animation_ended.emit("shoot")
		return
		
	# Reset is_shooting before dealing damage
	is_shooting = false
	
	var damage = get_total_damage()
	target_enemy.take_damage(damage)
	EventBus.publish_damage_dealt(damage, target_enemy)
	
	# Continue shooting if we still have a valid target
	if target_enemy and not target_enemy.get_is_dead():
		shoot(true)  # This will use attack_cooldown for subsequent shots
	else:
		EventBus.combat_animation_ended.emit("shoot")

func take_damage(amount: int, source: Node) -> void:
	EventBus.publish_damage_taken(amount, source)
	_enter_combat()  # Enter combat when taking damage

func get_total_damage() -> int:
	var base = combat_config.base_damage
	
	# Add weapon damage if equipped
	var weapon = GameState.player_data.equipment.get("weapon")
	if weapon and weapon is ItemData and weapon.stats.has("damage"):
		base += weapon.stats.damage
	
	return base

func _enemies_in_range() -> bool:
	# Logic to check if any enemies are in combat range
	return target_enemy != null and is_instance_valid(target_enemy) and not target_enemy.get_is_dead()

func equip_weapon(weapon: ItemData) -> void:
	if weapon.equip_slot == "weapon":
		EventBus.publish_weapon_changed(weapon)

func auto_shoot() -> void:
	if is_shooting or not target_enemy:
		return
	
	# Turn to face the target
	var direction_to_target = sign(target_enemy.global_position.x - character.global_position.x)
	character.movement.set_facing_direction(direction_to_target)
	
	shoot(true)	

func set_target(enemy: CharacterBody2D) -> void:
	target_enemy = enemy
	if target_enemy and current_combat_state == "combat":
		auto_shoot()  # Start auto-shooting when target is set

func _on_enemy_killed(enemy: BaseEnemy) -> void:
	if enemy == target_enemy:
		stop_auto_combat()

func _on_combat_state_changed(new_state: String) -> void:
	current_combat_state = new_state
	match new_state:
		"idle":
			target_enemy = null
			is_shooting = false
		"combat":
			if target_enemy and not target_enemy.get_is_dead():
				auto_shoot()  # Start auto-shooting when entering combat

func start_auto_combat(target: CharacterBody2D) -> void:
	if not target or target.get_is_dead():
		return
		
	auto_combat_enabled = true
	target_enemy = target
	EventBus.publish_auto_combat_started(target)
	_enter_combat()
	
	# Start with initial delay
	is_shooting = true
	EventBus.combat_animation_started.emit("shoot")
	animation_player.play("shoot")
	shoot_timer.start(initial_attack_delay)

func stop_auto_combat() -> void:
	auto_combat_enabled = false
	target_enemy = null
	is_shooting = false
	shoot_timer.stop()
	EventBus.publish_auto_combat_ended()
	_exit_combat()

func _on_auto_combat_timer_timeout() -> void:
	if auto_combat_enabled and target_enemy and not target_enemy.get_is_dead():
		shoot(true)
