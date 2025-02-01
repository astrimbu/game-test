class_name PlayerResources
extends Node

signal xp_changed(new_xp: int)
signal coins_changed(new_coins: int)
signal level_up(new_level: int)

func _ready() -> void:
	GameState.set_resources_node(self)

func add_xp(amount: int) -> void:
	GameState.player_data.xp += amount
	GameState.emit_resource_signal("xp_changed", GameState.player_data.xp)
	check_level_up()

func add_coins(amount: int) -> void:
	GameState.player_data.coins += amount
	GameState.emit_resource_signal("coins_changed", GameState.player_data.coins)

func check_level_up() -> void:
	var xp_for_next_level = GameState.player_data.level * 100  # Simple formula, adjust as needed
	if GameState.player_data.xp >= xp_for_next_level:
		GameState.player_data.level += 1
		level_up.emit(GameState.player_data.level)

# Getter methods to access state
func get_xp() -> int:
	return GameState.player_data.xp

func get_coins() -> int:
	return GameState.player_data.coins

func get_level() -> int:
	return GameState.player_data.level
