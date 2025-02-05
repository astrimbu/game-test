class_name PlayerData
extends Resource

# Basic player stats
@export var level: int = 1
@export var xp: int = 0
@export var coins: int = 0

# Inventory will be expanded later, for now just a placeholder
@export var inventory_size: int = 20
@export var inventory: Array[InventorySlot] = []
@export var equipment: Dictionary = {}  # Slot name -> ItemData

func _init():
	# Initialize inventory slots
	for i in range(inventory_size):
		inventory.append(InventorySlot.new())
	
	# Initialize empty equipment slots
	for slot in ["weapon", "head", "chest"]:
		equipment[slot] = null

func add_item(item: ItemData, amount: int = 1) -> int:
	var remaining = amount
	
	# First try to stack with existing items (if stackable)
	if item.stackable:
		for slot in inventory:
			if remaining <= 0:
				break
			if slot.can_add_item(item, remaining):
				remaining = slot.add_item(item, remaining)
	
	# Then try empty slots for remaining items
	if remaining > 0:
		for slot in inventory:
			if remaining <= 0:
				break
			if slot.item == null:
				remaining = slot.add_item(item, remaining)
	
	return remaining  # Returns 0 if all items were added, otherwise returns remaining items

func remove_item(slot_index: int, amount: int = 1) -> int:
	if slot_index < 0 or slot_index >= inventory.size():
		return 0
	return inventory[slot_index].remove_items(amount)

func equip_item(item: ItemData) -> ItemData:
	if item.equip_slot.is_empty():
		return null
		
	var previous_item = equipment.get(item.equip_slot)
	# Make sure we're returning a proper ItemData resource
	if previous_item is String:
		# If it's a path string, load the resource
		previous_item = load(previous_item) as ItemData
	elif not previous_item is ItemData:
		# If it's not a valid item, return null
		previous_item = null
		
	equipment[item.equip_slot] = item
	return previous_item

func unequip_item(slot: String) -> ItemData:
	var previous_item = equipment.get(slot)
	# Make sure we're returning a proper ItemData resource
	if previous_item is String:
		previous_item = load(previous_item) as ItemData
	elif not previous_item is ItemData:
		previous_item = null
		
	equipment.erase(slot)
	return previous_item

# Save/load methods
func to_dict() -> Dictionary:
	var inventory_data = []
	for slot in inventory:
		if slot.item:
			inventory_data.append(slot.to_dict())
		else:
			inventory_data.append(null)
			
	var equipment_data = {}
	for slot_name in equipment:
		var item = equipment[slot_name]
		if item is ItemData:
			equipment_data[slot_name] = item.resource_path
			
	return {
		"level": level,
		"xp": xp,
		"coins": coins,
		"inventory": inventory_data,
		"equipment": equipment_data,
	}

func from_dict(data: Dictionary) -> void:
	level = data.get("level", 1)
	xp = data.get("xp", 0)
	coins = data.get("coins", 0)
	
	# Load inventory
	var inventory_data = data.get("inventory", [])
	for i in range(min(inventory_data.size(), inventory.size())):
		if inventory_data[i]:
			inventory[i].from_dict(inventory_data[i])
	
	# Load equipment
	var equipment_data = data.get("equipment", {})
	for slot_name in equipment_data:
		var item_path = equipment_data[slot_name]
		if item_path and not item_path.is_empty():
			equipment[slot_name] = load(item_path) as ItemData
		else:
			equipment[slot_name] = null
