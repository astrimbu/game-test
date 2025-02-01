extends Node

var player_data: PlayerData
var world_state: WorldState
var resources_node: PlayerResources

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_data = PlayerData.new()
	world_state = WorldState.new()

func reset_state() -> void:
	player_data = PlayerData.new()
	world_state = WorldState.new()

# Will be used by SaveManager
func to_dict() -> Dictionary:
	return {
		"player": player_data.to_dict(),
		"world": world_state.to_dict(),
	}

func from_dict(data: Dictionary) -> void:
	player_data.from_dict(data.get("player", {}))
	world_state.from_dict(data.get("world", {}))

func set_resources_node(node: PlayerResources) -> void:
	resources_node = node

func emit_resource_signal(signal_name: String, value: Variant) -> void:
	if resources_node:
		match signal_name:
			"coins_changed":
				resources_node.coins_changed.emit(value)
			"xp_changed":
				resources_node.xp_changed.emit(value)
				resources_node.check_level_up()
