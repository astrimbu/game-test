class_name PlayerState
extends Node

# Virtual methods for state management
func enter_state(player: CharacterBody2D) -> void:
	pass

func exit_state(player: CharacterBody2D) -> void:
	pass

func update_state(player: CharacterBody2D, delta: float) -> void:
	pass

func handle_input(player: CharacterBody2D, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var global_click_pos = player.get_global_mouse_position()
		if event.pressed:
			# Handle mouse down - only check for items
			player.handle_mouse_down(global_click_pos)
		else:
			# Handle mouse up - check for other interactions if no item was picked up
			if not player.interaction.item_picked_up:
				player.set_state("moving_to_target")
				player.handle_mouse_up(global_click_pos)
	elif event.is_action_pressed("shoot"):
		player.set_state("shooting")

# Common utility methods that states might need
func apply_gravity(player: CharacterBody2D, delta: float) -> void:
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
 
