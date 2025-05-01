class_name ItemData
extends Resource

enum ItemType { CONSUMABLE, EQUIPMENT, RESOURCE }
enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC }

@export var id: String
@export var unique_id: String = ""
@export var name: String
@export var description: String
@export var type: ItemType
@export var rarity: ItemRarity = ItemRarity.COMMON
@export var icon: Texture2D
@export var stackable: bool = false
@export var max_stack: int = 1

# --- Display Properties ---
@export_group("Display Adjustments")
@export var dropped_scale: Vector2 = Vector2(1, 1)  # Scale when dropped on ground
@export var dropped_offset: Vector2 = Vector2.ZERO # Positional offset when dropped
@export var ui_icon_offset: Vector2 = Vector2.ZERO # Positional offset in UI slots
@export_group("") # End group

# Equipment-specific properties
@export var equip_slot: String = ""  # "head", "chest", "weapon", etc.
@export var stats: Dictionary = {}    # {"damage": 5, "defense": 3, etc.}

# Consumable-specific properties
@export var use_effect: Dictionary = {} # {"health": 20, "mana": 10, etc.}

func _init():
	if unique_id.is_empty():
		unique_id = str(Time.get_unix_time_from_system()) + "_" + str(randi())

func can_stack_with(other: ItemData) -> bool:
	return stackable and id == other.id

func to_dict() -> Dictionary:
	return {
		"id": id,
		"type": type,
		"stack_size": 1,  # Default for saving
		"stats": stats.duplicate()
	}
