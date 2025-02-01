class_name PlayerData
extends Resource

# Basic player stats
@export var level: int = 1
@export var xp: int = 0
@export var coins: int = 0

# Inventory will be expanded later, for now just a placeholder
@export var inventory: Array = []
@export var equipment: Dictionary = {}

# Save/load methods
func to_dict() -> Dictionary:
    return {
        "level": level,
        "xp": xp,
        "coins": coins,
        "inventory": inventory,
        "equipment": equipment,
    }

func from_dict(data: Dictionary) -> void:
    level = data.get("level", 1)
    xp = data.get("xp", 0)
    coins = data.get("coins", 0)
    inventory = data.get("inventory", [])
    equipment = data.get("equipment", {})
