class_name PlayerData
extends Resource

# Basic player stats
@export var level: int = 1
@export var xp: int = 0
@export var coins: int = 0

# Inventory will be expanded later, for now just a placeholder
@export var inventory_size: int = 20
@export var inventory: Array[InventorySlot]
@export var equipment: Dictionary = {}  # slot_name: ItemData

func _init():
	# Initialize empty inventory slots
	inventory.clear()
	for i in range(inventory_size):
		inventory.append(InventorySlot.new())

func add_item(item: ItemData, amount: int = 1) -> int:
	# First try to stack with existing items
	var remaining = amount
	for slot in inventory:
		if remaining <= 0:
			break
		if slot.can_add_item(item, remaining):
			remaining = slot.add_item(item, remaining)
	
	# Then try empty slots
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
	equipment[item.equip_slot] = item
	return previous_item

func unequip_item(slot: String) -> ItemData:
	var previous_item = equipment.get(slot)
	equipment.erase(slot)
	return previous_item  # Return the item that was unequipped, or null if nothing was equipped

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
	
	# Clear and reinitialize inventory
	inventory.clear()
	for i in range(inventory_size):
		inventory.append(InventorySlot.new())
	
	# Load saved inventory data if it exists
	var saved_inventory = data.get("inventory", [])
	for i in range(min(saved_inventory.size(), inventory.size())):
		if saved_inventory[i]:  # If slot has data
			# Convert the saved data to a dictionary if it isn't already
			var slot_data = saved_inventory[i]
			if not slot_data is Dictionary:
				slot_data = {
					"item": slot_data.item if slot_data.get("item") else "",
					"amount": slot_data.amount if slot_data.get("amount") else 0
				}
			inventory[i].from_dict(slot_data)
	
	equipment = data.get("equipment", {})
