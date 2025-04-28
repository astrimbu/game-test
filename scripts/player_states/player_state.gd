class_name PlayerState
extends RefCounted # Use RefCounted for states if they don't need node features

# Base class for all player states

# Called when entering the state
func enter_state(_player: CharacterBody2D) -> void:
	pass

# Called every physics frame
func update_state(_player: CharacterBody2D, _delta: float) -> void:
	pass

# Called when exiting the state
func exit_state(_player: CharacterBody2D) -> void:
	pass

# Called by player's _unhandled_input
func handle_input(_player: CharacterBody2D, _event: InputEvent) -> void:
	pass

# Common physics logic
func apply_gravity(player: CharacterBody2D, delta: float) -> void:
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta

# Common utility methods that states might need
# func apply_gravity(player: CharacterBody2D, delta: float) -> void:
# 	if not player.is_on_floor():
# 		player.velocity.y += player.gravity * delta
 
