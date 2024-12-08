class_name EnemyMovementController
extends Node

const PATROL_SPEED = 100
const EDGE_CHECK_DISTANCE = 20

# Configuration
@export var can_patrol := true
@export var patrol_range := 200.0
@export var movement_speed := 100.0

# References
var parent: CharacterBody2D
var sprite: Node2D

# State
var patrol_start_position: Vector2
var moving_right := true
var can_move := true

func _ready():
	parent = get_parent()
	# Wait one frame to ensure parent is ready
	await get_tree().process_frame
	patrol_start_position = parent.global_position

func init(sprite_node: Node2D):
	sprite = sprite_node

func process_movement(_delta: float) -> Vector2:
	if !can_move:
		return Vector2.ZERO
		
	if !can_patrol:
		return Vector2.ZERO
		
	return _calculate_patrol_velocity()

func _calculate_patrol_velocity() -> Vector2:
	# Check for edges and walls
	var should_turn = _should_change_direction()
	
	if should_turn:
		moving_right = !moving_right
	
	# Check if we're too far from patrol start
	var distance_from_start = parent.global_position.x - patrol_start_position.x
	if abs(distance_from_start) > patrol_range:
		moving_right = distance_from_start < 0
	
	# Update sprite direction
	if sprite:
		sprite.flip_h = !moving_right
	
	# Return movement velocity
	return Vector2(movement_speed if moving_right else -movement_speed, 0)

func _should_change_direction() -> bool:
	var space_state = parent.get_world_2d().direct_space_state
	var query_parameters = PhysicsRayQueryParameters2D.create(
		parent.global_position,
		parent.global_position + Vector2(EDGE_CHECK_DISTANCE if moving_right else -EDGE_CHECK_DISTANCE, EDGE_CHECK_DISTANCE),
		1  # Collision mask for world/platforms
	)
	
	var result = space_state.intersect_ray(query_parameters)
	return !result  # Return true if no ground ahead (edge detected)

func reset_movement():
	patrol_start_position = parent.global_position
	moving_right = true
	can_move = true

func stop_movement():
	can_move = false

func resume_movement():
	can_move = true 