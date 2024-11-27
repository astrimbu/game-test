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
var shoot_timer: Timer = null

func _ready():
	# Initialize and configure the shoot timer
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
	perform_shoot()
	
	if animation_player.is_playing() and animation_player.current_animation == "shoot":
		# Schedule the next shot after the full animation duration (0.6 seconds)
		shoot_timer.start(0.6)  # Adjusted from 0.3 to 0.6 seconds for proper cooldown
	else:
		_stop_shooting()
	
	# For auto shooting, check if the target is still valid
	if target_enemy and not target_enemy.is_dead:
		# No additional action needed; the timer controls the shooting rate
		pass
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
				_stop_shooting()

func _stop_shooting() -> void:
	if not is_shooting:
		return
	
	is_shooting = false
	stopped_shooting.emit()
	animation_player.play("idle")
	shoot_timer.stop()

func set_target(enemy: CharacterBody2D) -> void:
	target_enemy = enemy
