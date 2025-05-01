extends Node

signal inventory_updated
signal equipment_updated(slot_type: String, item: ItemData)

func _ready() -> void:
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.game_state_reset.connect(_on_game_state_reset)
	
	# Initial state update
	for slot_type in GameState.player_data.equipment.keys():
		equipment_updated.emit(slot_type, GameState.player_data.equipment[slot_type])
	inventory_updated.emit()

func _on_item_picked_up(item: ItemData) -> void:
	add_item_to_inventory(item)

func _on_game_state_reset() -> void:
	print("InventoryManager: Handling game state reset")
	# Force a UI refresh after game state is reset
	inventory_updated.emit()
	# Emit equipment_updated for each equipment slot
	for slot_type in GameState.player_data.equipment.keys():
		equipment_updated.emit(slot_type, null)

func equip_item(item: ItemData, source_slot: int = -1) -> bool:
	if not item or item.type != ItemData.ItemType.EQUIPMENT:
		return false
		
	var previous_item = GameState.player_data.equip_item(item)
	
	# Handle the source inventory slot
	if source_slot >= 0:
		if previous_item:
			# Swap with previous item
			GameState.player_data.inventory[source_slot].item = previous_item
		else:
			# Clear the slot
			GameState.player_data.inventory[source_slot].remove_items(1)
	
	equipment_updated.emit(item.equip_slot, item)
	inventory_updated.emit()
	return true

func unequip_item(slot_type: String, target_slot: int = -1) -> bool:
	var item = GameState.player_data.unequip_item(slot_type)
	if not item:
		return false
		
	var success = add_item_to_inventory(item, target_slot)
	if success:
		equipment_updated.emit(slot_type, null)
		inventory_updated.emit()
	return success

func add_item_to_inventory(item: ItemData, target_slot: int = -1) -> bool:
	if target_slot >= 0:
		# Try to add to specific slot
		if target_slot < GameState.player_data.inventory.size():
			var target = GameState.player_data.inventory[target_slot]
			if not target.item:
				target.item = item
				target.amount = 1
				inventory_updated.emit()
				return true
	
	# If no target slot or target slot was full, find first available
	for slot in GameState.player_data.inventory:
		if not slot.item:
			slot.item = item
			slot.amount = 1
			inventory_updated.emit()
			return true
	
	return false

func move_inventory_item(from_slot: int, to_slot: int) -> bool:
	if from_slot == to_slot:
		return false
		
	var inventory = GameState.player_data.inventory
	if from_slot < 0 or from_slot >= inventory.size() or to_slot < 0 or to_slot >= inventory.size():
		return false
	
	var from_slot_data = inventory[from_slot]
	var to_slot_data = inventory[to_slot]
	
	# Swap items between slots
	var temp_item = to_slot_data.item
	var temp_amount = to_slot_data.amount
	
	to_slot_data.item = from_slot_data.item
	to_slot_data.amount = from_slot_data.amount
	
	from_slot_data.item = temp_item
	from_slot_data.amount = temp_amount
	
	inventory_updated.emit()
	return true

func get_inventory_slot_index(slot_data: InventorySlot) -> int:
	return GameState.player_data.inventory.find(slot_data)

# Function required by EquipmentSlotUI to get the initial item
func get_equipped_item(slot_type: String) -> ItemData:
	if GameState.player_data and GameState.player_data.equipment.has(slot_type):
		var item = GameState.player_data.equipment[slot_type]
		# Ensure we return ItemData or null
		if item is ItemData:
			return item
	return null # Return null if slot doesn't exist or item isn't ItemData
