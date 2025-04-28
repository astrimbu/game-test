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

# Track mouse button state
var is_mouse_button_down: bool = false
# Track if any item was picked up during the current drag
var did_pickup_during_drag: bool = false
# Cooldown to prevent rapid re-pickup
var pickup_cooldown: float = 0.0
const PICKUP_COOLDOWN_DURATION: float = 0.1 # Seconds

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

func _physics_process(delta: float) -> void:
	# Update pickup cooldown
	if pickup_cooldown > 0.0:
		pickup_cooldown -= delta
	
	# Handle continuous item pickup while mouse is down
	if is_mouse_button_down and pickup_cooldown <= 0.0:
		_try_pickup_item_at(character.get_global_mouse_position())

	# Update target indicator position ONLY if we're targeting a valid enemy
	if target_indicator and character and character.combat:
		var enemy = character.combat.target_enemy
		# Check if enemy is valid and alive
		if is_instance_valid(enemy) and not enemy.get_is_dead():
			# Enemy is valid and alive, update indicator position
			var offset = enemy.indicator_offset if "indicator_offset" in enemy else 0.0
			var indicator_pos = enemy.global_position - Vector2(0, offset)
			# Use the interaction component's own reference if available
			if target_indicator: # Ensure the node reference is valid
				target_indicator.global_position = indicator_pos
				# Make sure it's visible if we are updating it
				# This might be redundant if Player's intent handlers handle visibility,
				# but ensures it stays visible if it somehow got hidden.
				target_indicator.visible = true 
	# No 'else' clause here, so we don't hide the indicator if there's no enemy
	# (e.g., when moving to a point)

func handle_mouse_down(clicked_pos: Vector2) -> void:
	_handle_mouse_down(clicked_pos)

func handle_mouse_up(clicked_pos: Vector2) -> void:
	_handle_mouse_up(clicked_pos)

func handle_click(clicked_pos: Vector2) -> void:
	handle_mouse_down(clicked_pos)
	handle_mouse_up(clicked_pos)

func _handle_mouse_down(clicked_pos: Vector2) -> void:
	is_mouse_button_down = true
	did_pickup_during_drag = false # Reset drag pickup flag

# Separated item pickup logic into its own function
func _try_pickup_item_at(check_pos: Vector2) -> void:
	var space_state = character.get_world_2d().direct_space_state
	
	# Check for items only
	var item_params = PhysicsPointQueryParameters2D.new()
	item_params.position = check_pos
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
				did_pickup_during_drag = true # Set flag if item picked up
				pickup_cooldown = PICKUP_COOLDOWN_DURATION # Start cooldown
				if target_indicator:
					target_indicator.visible = false

func _handle_mouse_up(_clicked_pos: Vector2) -> void:
	is_mouse_button_down = false
	
	# If an item was picked up during the drag, don't process other interactions like move/attack
	if did_pickup_during_drag:
		return
	
	var space_state = character.get_world_2d().direct_space_state
	
	# Check for NPCs and Enemies
	var interact_params = PhysicsPointQueryParameters2D.new()
	interact_params.position = _clicked_pos
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
	var walkable_pos = get_walkable_position(_clicked_pos)
	if walkable_pos != Vector2.ZERO:
		intent_move_to.emit(walkable_pos)

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
	if result:
		var return_pos = Vector2(clicked_pos.x, result.position.y)
		return return_pos
	
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
