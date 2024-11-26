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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var global_click_pos = player.get_global_mouse_position()
		player.set_state("moving_to_target")
		player.handle_click(global_click_pos)
	elif event.is_action_pressed("shoot"):
		player.set_state("shooting")

# Common utility methods that states might need
func apply_gravity(player: CharacterBody2D, delta: float) -> void:
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
 
