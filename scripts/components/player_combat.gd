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

func _ready() -> void:
	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	shoot_timer.connect("timeout", Callable(self, "_on_shoot_timer_timeout"))
	add_child(shoot_timer)

func shoot(is_auto: bool = false) -> void:
	if is_auto:
		auto_shoot()
		return
	
	if is_shooting:
		return
	
	is_shooting = true
	_enter_combat()
	EventBus.combat_animation_started.emit("shoot")  # Generic "shoot" for now
	animation_player.play("shoot")
	shoot_timer.start(0.2)

func _enter_combat() -> void:
	if current_combat_state != "combat":
		current_combat_state = "combat"
		EventBus.publish_combat_state_change("combat")

func _exit_combat() -> void:
	if current_combat_state != "idle":
		current_combat_state = "idle"
		EventBus.publish_combat_state_change("idle")

func _on_shoot_timer_timeout() -> void:
	if target_enemy and not target_enemy.get_is_dead():
		var damage = get_total_damage()
		target_enemy.take_damage(damage)
		EventBus.publish_damage_dealt(damage, target_enemy)
	
	is_shooting = false
	EventBus.combat_animation_ended.emit("shoot")
	
	# Only exit combat if no enemies are nearby
	if not _enemies_in_range():
		_exit_combat()

func take_damage(amount: int, source: Node) -> void:
	EventBus.publish_damage_taken(amount, source)
	_enter_combat()  # Enter combat when taking damage

func get_total_damage() -> int:
	var base = combat_config.base_damage
	
	# Add weapon damage if equipped
	var weapon = GameState.player_data.equipment.get("weapon")
	if weapon and weapon.stats.has("damage"):
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
	
	is_shooting = true
	_enter_combat()
	animation_player.play("shoot")
	
	# Schedule the first shot after 0.2 seconds to match animation timing
	shoot_timer.start(0.2)

func set_target(enemy: CharacterBody2D) -> void:
	target_enemy = enemy
