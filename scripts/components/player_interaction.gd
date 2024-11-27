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

# Add a constant for pickup range
const PICKUP_RANGE := 2000.0  # Adjust this value as needed

# Flag to track if an item was picked up on mouse down
var item_picked_up: bool = false

func _physics_process(_delta: float) -> void:
	# Update target indicator position if we're targeting an enemy
	if character.combat and character.combat.target_enemy and target_indicator:
		var enemy = character.combat.target_enemy
		if not enemy.is_dead:
			_update_target_indicator(enemy.global_position - Vector2(0, enemy.indicator_offset))

func handle_mouse_down(clicked_pos: Vector2) -> void:
	_handle_mouse_down(clicked_pos)

func handle_mouse_up(clicked_pos: Vector2) -> void:
	_handle_mouse_up(clicked_pos)

func handle_click(clicked_pos: Vector2) -> void:
	handle_mouse_down(clicked_pos)
	handle_mouse_up(clicked_pos)

func _handle_mouse_down(clicked_pos: Vector2) -> void:
	item_picked_up = false  # Reset the flag
	var space_state = character.get_world_2d().direct_space_state
	
	# Check for items only
	var item_params = PhysicsPointQueryParameters2D.new()
	item_params.position = clicked_pos
	item_params.collision_mask = 0b10000  # Layer 5 (Items) only
	item_params.collide_with_areas = true
	item_params.collide_with_bodies = false
	
	var item_results = space_state.intersect_point(item_params)
	if not item_results.is_empty():
		var item = item_results[0].collider
		if item is DroppedItem:
			var distance = character.global_position.distance_to(item.global_position)
			if distance <= PICKUP_RANGE:
				item.collect()
				item_picked_up = true
				if target_indicator:
					target_indicator.visible = false

func _handle_mouse_up(clicked_pos: Vector2) -> void:
	# If an item was picked up on mouse down, don't process any other interactions
	if item_picked_up:
		return
	
	var space_state = character.get_world_2d().direct_space_state
	
	# Check for NPCs and Enemies
	var interact_params = PhysicsPointQueryParameters2D.new()
	interact_params.position = clicked_pos
	interact_params.collision_mask = 0b1100  # Layers 3 (Enemy) and 4 (NPC)
	interact_params.collide_with_bodies = true
	interact_params.collide_with_areas = false
	
	var interact_results = space_state.intersect_point(interact_params)
	if not interact_results.is_empty():
		var clicked_object = interact_results[0].collider
		if clicked_object.get_collision_layer_value(4):  # NPC check
			_handle_npc_interaction(clicked_object)
			return
		elif clicked_object.get_collision_layer_value(3):  # Enemy check
			_handle_enemy_interaction(clicked_object)
			return
	
	# If nothing interactive was clicked, handle as movement
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
		# Set target position for movement
		set_movement_target(get_walkable_position(enemy.global_position))
		# Update indicator above enemy
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
