class_name PlayerResources
extends Node

func _ready() -> void:
	GameState.set_resources_node(self)
	# Connect to EventBus signals
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.coins_gained.connect(_on_coins_gained)

func _on_xp_gained(amount: int) -> void:
	GameState.player_data.xp += amount
	check_level_up()

func _on_coins_gained(amount: int) -> void:
	GameState.player_data.coins += amount

func check_level_up() -> void:
	var xp_for_next_level = GameState.player_data.level * 100  # Simple formula, adjust as needed
	if GameState.player_data.xp >= xp_for_next_level:
		GameState.player_data.level += 1
		EventBus.level_up.emit(GameState.player_data.level)

# Getter methods to access state
func get_xp() -> int:
	return GameState.player_data.xp

func get_coins() -> int:
	return GameState.player_data.coins

func get_level() -> int:
	return GameState.player_data.level
