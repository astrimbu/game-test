class_name PlayerInteraction
extends Node

signal target_reached(target)
signal started_npc_interaction(npc)
signal ended_npc_interaction(npc)
signal target_changed(new_target_position)

@export var config: PlayerConfig
@export var character: CharacterBody2D
@export var target_indicator: Node2D

var target_position: Vector2 = Vector2.ZERO
var target_npc: CharacterBody2D = null
var ray_length := 50

func handle_click(clicked_pos: Vector2) -> void:
	var space_state = character.get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = clicked_pos
	params.collision_mask = 0b1100  # NPC and Enemy layers
	params.collide_with_bodies = true
	
	var results = space_state.intersect_point(params)
	
	if not results.is_empty():
		var clicked_object = results[0].collider
		if clicked_object.get_collision_layer_value(4):  # NPC check
			_handle_npc_interaction(clicked_object)
			return
		elif clicked_object.get_collision_layer_value(3):  # Enemy check
			_handle_enemy_interaction(clicked_object)
			return
	
	# If no interactive object clicked, handle as movement
	set_movement_target(get_walkable_position(clicked_pos))

func _handle_npc_interaction(npc: CharacterBody2D) -> void:
	target_npc = npc
	
	# Calculate interaction position
	var height_difference = abs(npc.global_position.y - character.global_position.y)
	var direction = sign(npc.global_position.x - character.global_position.x)
	
	if height_difference <= 10:
		target_position = npc.global_position - Vector2(direction * config.INTERACTION_DISTANCE, 0)
	else:
		target_position = get_walkable_position(npc.global_position - Vector2(direction * 50, 0))
	
	_update_target_indicator(npc.global_position - Vector2(0, npc.indicator_offset))
	target_changed.emit(target_position)

func _handle_enemy_interaction(enemy: CharacterBody2D) -> void:
	if character.combat:
		character.combat.set_target(enemy)
		set_movement_target(get_walkable_position(enemy.global_position))
		_update_target_indicator(enemy.global_position - Vector2(0, enemy.indicator_offset))

func set_movement_target(pos: Vector2) -> void:
	target_position = pos
	_update_target_indicator(pos)
	target_changed.emit(pos)

func _update_target_indicator(pos: Vector2) -> void:
	if target_indicator:
		target_indicator.global_position = pos
		target_indicator.visible = true

func get_walkable_position(clicked_pos: Vector2) -> Vector2:
	var space_state = character.get_world_2d().direct_space_state
	
	# Try direct ray first
	var params = PhysicsRayQueryParameters2D.create(
		clicked_pos + Vector2(0, -20),
		clicked_pos + Vector2(0, 20),
		1  # Ground layer
	)
	
	var result = space_state.intersect_ray(params)
	if result:
		return result.position
	
	# Try longer ray if no direct hit
	params = PhysicsRayQueryParameters2D.create(
		clicked_pos + Vector2(0, -ray_length),
		clicked_pos + Vector2(0, ray_length),
		1
	)
	
	result = space_state.intersect_ray(params)
	if result and result.position.y >= character.position.y - 20:
		return Vector2(clicked_pos.x, result.position.y)
	
	return character.position

func clear_targets() -> void:
	target_npc = null
	target_position = Vector2.ZERO
	if target_indicator:
		target_indicator.visible = false 