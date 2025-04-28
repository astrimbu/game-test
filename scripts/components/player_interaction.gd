class_name PlayerInteraction
extends Node

signal target_reached(target)
signal started_npc_interaction(npc)
signal ended_npc_interaction(npc)
signal target_changed(new_target_position)

# New Intent Signals
signal intent_move_to(position: Vector2)
signal intent_attack(enemy: CharacterBody2D)
signal intent_interact(npc: CharacterBody2D)

@export var config: PlayerConfig # RESTORE this export
@export var character: CharacterBody2D
# @export var target_indicator: Node2D # REMOVE this export
var target_indicator: Node2D = null # Keep the variable, but don't export

var target_position: Vector2 = Vector2.ZERO
var target_npc: CharacterBody2D = null
var ray_length := 50

# Add a constant for pickup range
const PICKUP_RANGE := 2000.0  # Adjust this value as needed
const PUNCH_RANGE := 15.0 # Range within which the player can punch

# Flag to track if an item was picked up on mouse down
var item_picked_up: bool = false

func _ready() -> void:
	# Find the target indicator node, assuming it's a sibling of the Player node
	# IMPORTANT: Assumes the node in the World scene is named "TargetIndicator"
	# and is a direct child of the same node as the Player instance.
	var player_parent = character.get_parent()
	if player_parent:
		target_indicator = player_parent.find_child("TargetIndicator", false, false) # Non-recursive search among siblings
	
	# Fallback: If not found as sibling, try searching from root (previous method)
	if not target_indicator:
		target_indicator = get_tree().get_root().find_child("TargetIndicator", true, false)

	if not target_indicator:
		# Use push_warning instead of print_warning
		push_warning("PlayerInteraction: Could not find 'TargetIndicator' node in the scene tree (checked siblings and root).")
	else:
		# Ensure it's hidden initially
		target_indicator.visible = false

func _physics_process(_delta: float) -> void:
	# Update target indicator position if we're targeting an enemy
	if target_indicator and character and character.combat: # Add null checks
		var enemy = character.combat.target_enemy
		# DEBUG:
		# print("DEBUG Interaction: Physics process running. Target Indicator node: ", target_indicator)
		# print("DEBUG Interaction: Current target_enemy: ", enemy)
		
		if is_instance_valid(enemy):
			if not enemy.get_is_dead():
				# Enemy is valid and alive, update indicator position
				# Safely get offset, default to 0.0 if property doesn't exist
				var offset = enemy.indicator_offset if "indicator_offset" in enemy else 0.0
				var target_pos = enemy.global_position - Vector2(0, offset)
				_update_target_indicator(target_pos)
			else:
				# Enemy is valid but dead, hide indicator
				if target_indicator.visible:
					target_indicator.visible = false
		else:
			# No valid enemy target, hide indicator
			if target_indicator.visible:
				target_indicator.visible = false
	# Consider if indicator should also be hidden if character.combat is null?
	# The outer check handles this implicitly.

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
			intent_interact.emit(clicked_object)
			return
		elif clicked_object.get_collision_layer_value(3):  # Enemy check
			intent_attack.emit(clicked_object)
			return
	
	# If nothing interactive was clicked, handle as movement intent
	var walkable_pos = get_walkable_position(clicked_pos)
	if walkable_pos != Vector2.ZERO:
		intent_move_to.emit(walkable_pos)

func _update_target_indicator(pos: Vector2) -> void:
	if target_indicator:
		target_indicator.global_position = pos
		target_indicator.visible = true

func get_walkable_position(clicked_pos: Vector2) -> Vector2:
	print("DEBUG: get_walkable_position called with clicked_pos: ", clicked_pos) # DEBUG
	var space_state = character.get_world_2d().direct_space_state
	
	# Try direct ray first
	var params = PhysicsRayQueryParameters2D.create(
		clicked_pos + Vector2(0, -20),
		clicked_pos + Vector2(0, 20),
		1  # Ground layer
	)
	
	var result = space_state.intersect_ray(params)
	print("DEBUG: Direct raycast result: ", result) # DEBUG
	if result:
		print("DEBUG: Direct raycast hit. Returning: ", result.position) # DEBUG
		return result.position
	
	# Try longer ray if no direct hit
	params = PhysicsRayQueryParameters2D.create(
		clicked_pos + Vector2(0, -ray_length),
		clicked_pos + Vector2(0, ray_length),
		1
	)
	
	result = space_state.intersect_ray(params)
	print("DEBUG: Longer raycast result: ", result) # DEBUG
	if result:
		var return_pos = Vector2(clicked_pos.x, result.position.y) # DEBUG
		print("DEBUG: Longer raycast hit valid position. Returning: ", return_pos) # DEBUG
		return return_pos
	
	print("DEBUG: NO WALKABLE POSITION FOUND, RETURNING Vector2.ZERO") # DEBUG Renamed from NULL VECTOR for clarity
	# Return Vector2.ZERO to indicate invalid position
	return Vector2.ZERO

# New function to clear interaction targets
func clear_targets() -> void:
	print("DEBUG: PlayerInteraction clear_targets called")
	target_position = Vector2.ZERO
	target_npc = null
	if target_indicator:
		target_indicator.visible = false

# func _get_configuration_warnings() -> PackedStringArray:
# 	if not character:
# 		return ["Character node not assigned!"]
# 	return []
