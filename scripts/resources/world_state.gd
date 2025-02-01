class_name WorldState
extends Resource

@export var current_map: String = ""
@export var unlocked_maps: Array[String] = []
@export var active_quests: Array[String] = []
@export var completed_quests: Array[String] = []

func to_dict() -> Dictionary:
    return {
        "current_map": current_map,
        "unlocked_maps": unlocked_maps,
        "active_quests": active_quests,
        "completed_quests": completed_quests,
    }

func from_dict(data: Dictionary) -> void:
    current_map = data.get("current_map", "")
    unlocked_maps = data.get("unlocked_maps", [])
    active_quests = data.get("active_quests", [])
    completed_quests = data.get("completed_quests", [])
