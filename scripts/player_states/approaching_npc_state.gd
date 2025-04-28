class_name ApproachingNPCState
extends PlayerState

# TODO: Get interaction distance from config
const INTERACTION_DISTANCE = 50.0 # Example value
const HORIZONTAL_THRESHOLD = 5.0

func enter_state(player: CharacterBody2D) -> void:
	print("Enter ApproachingNPCState")
	if not is_instance_valid(player.target_npc):
		player.request_state_change("idle")
		return
	player.animation_player.play("walk")
	# Ensure target indicator is visible for the NPC
	player._update_target_indicator(player.target_npc.global_position - Vector2(0, player.target_npc.indicator_offset))

func update_state(player: CharacterBody2D, delta: float) -> void:
	if not is_instance_valid(player.target_npc):
		player.request_state_change("idle")
		return

	apply_gravity(player, delta)

	# Calculate target position near the NPC
	# Use a fixed offset for now, similar to old interaction logic
	var direction_to_npc = sign(player.target_npc.global_position.x - player.global_position.x)
	# Prevent division by zero if direction is 0
	if direction_to_npc == 0: direction_to_npc = 1 
	var target_pos = player.target_npc.global_position - Vector2(direction_to_npc * player.config.INTERACTION_DISTANCE, 0)
	
	# Optionally use get_walkable_position if direct positioning is problematic
	# target_pos = player.interaction.get_walkable_position(target_pos)
	# if target_pos == Vector2.ZERO: # Handle invalid path
	#     print("WARN: Cannot find walkable path to NPC, idling.")
	#     player.movement.move(0)
	#     player.move_and_slide()
	#     player.request_state_change("idle")
	#     return

	# Check distance to the calculated target position
	var distance_to_target = player.global_position.distance_to(target_pos)

	# Check if close enough to interact
	if distance_to_target <= HORIZONTAL_THRESHOLD: # Use threshold for arrival
		player.movement.move(0) # Stop horizontal movement
		player.move_and_slide() # Apply stop and gravity
		
		# Face the NPC before interacting
		player.sprite.flip_h = (player.target_npc.global_position.x < player.global_position.x)
		
		# Trigger interaction
		if player.target_npc.has_method("start_interaction"):
			player.target_npc.start_interaction()
		else:
			print("WARN: Target NPC does not have start_interaction method.")
		
		player.interaction.clear_targets() # Clear NPC target after interaction
		player.request_state_change("idle")
		return

	# Move towards the calculated target position
	var move_direction = sign(target_pos.x - player.position.x)
	player.movement.move(move_direction)
	
	# Handle jumping/falling logic (similar to ApproachingEnemyState)
	# TODO: Add jump/fall logic if needed for approaching NPCs

	# Flip sprite based on movement direction
	if move_direction != 0:
		player.sprite.flip_h = (move_direction < 0)

	player.move_and_slide()

func exit_state(player: CharacterBody2D) -> void:
	print("Exit ApproachingNPCState")
	player.movement.move(0) # Ensure movement stops
	# Clear target explicitly? Player intent handler already did, but maybe good practice?
	# player.interaction.target_npc = null

func handle_input(player: CharacterBody2D, event: InputEvent) -> void:
	# Allow new click actions to interrupt approaching
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		player.handle_mouse_down(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		player.handle_mouse_up(event.position) 