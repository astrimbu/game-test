class_name InventorySlot
extends Resource

@export var item: ItemData = null
@export var amount: int = 0

func can_add_item(new_item: ItemData, amount_to_add: int) -> bool:
	if item == null:
		return true
	return item == new_item and amount + amount_to_add <= item.max_stack_size

func add_item(new_item: ItemData, amount_to_add: int) -> int:
	if item == null:
		item = new_item
		amount = min(amount_to_add, new_item.max_stack_size)
		return amount_to_add - amount
	elif item == new_item:
		var space_left = item.max_stack_size - amount
		var amount_added = min(amount_to_add, space_left)
		amount += amount_added
		return amount_to_add - amount_added
	return amount_to_add

func remove_items(amount_to_remove: int) -> int:
	var amount_removed = min(amount, amount_to_remove)
	amount -= amount_removed
	if amount <= 0:
		item = null
		amount = 0
	return amount_removed

func to_dict() -> Dictionary:
	return {
		"item": item.resource_path if item else "",
		"amount": amount
	}

func from_dict(data: Dictionary) -> void:
	amount = data.get("amount", 0)
	var item_path = data.get("item", "")
	if item_path:
		item = load(item_path) as ItemData
	else:
		item = null
