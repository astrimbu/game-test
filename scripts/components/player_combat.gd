class_name PlayerCombat
extends Node

signal started_shooting
signal stopped_shooting
signal hit_enemy(enemy)
signal killed_enemy(enemy)

@export var config: PlayerConfig
@export var combat_config: CombatConfig
@export var character: CharacterBody2D
@export var animation_player: AnimationPlayer

var is_shooting := false
var target_enemy: CharacterBody2D = null
var shoot_timer: Timer = null

func _ready():
	# Initialize and configure the shoot timer
	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	shoot_timer.connect("timeout", Callable(self, "_on_shoot_timer_timeout"))
	add_child(shoot_timer)

func get_total_damage() -> int:
	var base = combat_config.base_damage
	# Later we'll add equipment bonuses from GameState.player_data.equipment
	return base

func shoot(is_auto: bool = false) -> void:
	if is_auto:
		auto_shoot()
		return
	
	if is_shooting:
		return
	
	is_shooting = true
	started_shooting.emit()
	animation_player.play("shoot")
	
	# Schedule the first shot after 0.2 seconds to match animation timing
	shoot_timer.start(0.2)

func auto_shoot() -> void:
	if is_shooting or not target_enemy:
		return
	
	# Turn to face the target
	var direction_to_target = sign(target_enemy.global_position.x - character.global_position.x)
	character.movement.set_facing_direction(direction_to_target)
	
	is_shooting = true
	started_shooting.emit()
	animation_player.play("shoot")
	
	# Schedule the first shot after 0.2 seconds to match animation timing
	shoot_timer.start(0.2)

func _on_shoot_timer_timeout() -> void:
	if target_enemy and not target_enemy.is_dead:
		var damage = get_total_damage()
		target_enemy.take_damage(damage)
		
		if target_enemy.is_dead:
			killed_enemy.emit(target_enemy)
		else:
			hit_enemy.emit(target_enemy)
	
	is_shooting = false
	stopped_shooting.emit()

func set_target(enemy: CharacterBody2D) -> void:
	target_enemy = enemy
