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
	pass

# Common utility methods that states might need
func apply_gravity(player: CharacterBody2D, delta: float) -> void:
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta

func handle_click(player: CharacterBody2D, clicked_pos: Vector2) -> void:
	# Don't interrupt if we're in the middle of a manual shooting animation
	if player.is_shooting and not player.target_enemy:
		return
		
	player.handle_click(clicked_pos) 