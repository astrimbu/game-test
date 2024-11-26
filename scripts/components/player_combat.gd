class_name PlayerCombat
extends Node

signal started_shooting
signal stopped_shooting
signal hit_enemy(enemy)
signal killed_enemy(enemy)

@export var config: PlayerConfig
@export var character: CharacterBody2D
@export var animation_player: AnimationPlayer

var is_shooting := false
var target_enemy: CharacterBody2D = null

func shoot(is_auto: bool = false) -> void:
	if is_auto:
		auto_shoot()
		return
	
	if is_shooting:
		return
	
	is_shooting = true
	started_shooting.emit()
	animation_player.play("shoot")
	
	# Add delay to match animation
	await character.get_tree().create_timer(0.2).timeout
	
	perform_shoot()
	
	# Wait for animation
	await animation_player.animation_finished
	
	if Input.is_action_pressed("ui_accept"):
		shoot(false)
	else:
		_stop_shooting()

func auto_shoot() -> void:
	if is_shooting or not target_enemy:
		return
	
	# Turn to face the target
	var direction_to_target = sign(target_enemy.global_position.x - character.global_position.x)
	character.movement.set_facing_direction(direction_to_target)
	
	is_shooting = true
	started_shooting.emit()
	animation_player.play("shoot")
	
	# Add delay to match animation
	await character.get_tree().create_timer(0.2).timeout
	
	if not target_enemy or target_enemy.is_dead:
		_stop_shooting()
		return
	
	perform_shoot()
	
	# Wait for animation
	await animation_player.animation_finished
	
	# Important: Reset shooting state and check target before continuing
	is_shooting = false
	
	# Schedule the next shot after a small delay
	if target_enemy and not target_enemy.is_dead:
		var timer = character.get_tree().create_timer(0.1)
		await timer.timeout
		if target_enemy and not target_enemy.is_dead:  # Check again after delay
			auto_shoot()  # Start next shot
	else:
		_stop_shooting()

func perform_shoot() -> void:
	# Calculate shoot position and direction
	var shoot_position = character.global_position + Vector2(0, -60)
	var shoot_direction = character.scale.x * -1  # Convert scale to direction
	
	# Create raycast
	var space_state = character.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		shoot_position,
		shoot_position + Vector2(shoot_direction * 1000, 0)
	)
	query.collision_mask = 0b100  # Enemy layer
	
	var result = space_state.intersect_ray(query)
	if result:
		var enemy = result.collider
		if enemy.has_method("hit"):
			enemy.hit(shoot_position)
			hit_enemy.emit(enemy)
			if enemy.is_dead:
				killed_enemy.emit(enemy)
				target_enemy = null

func _stop_shooting() -> void:
	is_shooting = false
	stopped_shooting.emit()
	animation_player.play("idle")

func set_target(enemy: CharacterBody2D) -> void:
	target_enemy = enemy 
