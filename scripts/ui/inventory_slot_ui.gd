class_name InventorySlotUI
extends Panel

@onready var item_icon: TextureRect = $ItemIcon
@onready var quantity_label: Label = $QuantityLabel

var slot_index: int = -1
var slot_data: InventorySlot = null

func update_slot(new_slot: InventorySlot) -> void:
	slot_data = new_slot
	print("InventorySlotUI ", slot_index, " updating:")
	
	if slot_data and slot_data.item:
		print("- Has item:", slot_data.item.name)
		print("- Icon texture:", slot_data.item.icon)
		item_icon.texture = slot_data.item.icon
		item_icon.visible = true
		
		if slot_data.item.stackable:
			quantity_label.text = str(slot_data.amount)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
	else:
		print("- Empty slot")
		item_icon.texture = null
		item_icon.visible = false
		quantity_label.visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_on_left_click()
			MOUSE_BUTTON_RIGHT:
				_on_right_click()

func _on_left_click() -> void:
	if slot_data and slot_data.item:
		print("Clicked on slot with item:", slot_data.item.name)
		if slot_data.item.type == ItemData.ItemType.EQUIPMENT:
			print("Attempting to equip item")
			var previous_item = GameState.player_data.equip_item(slot_data.item)
			if previous_item:
				print("Swapped with previously equipped item:", previous_item.name)
				slot_data.item = previous_item
			else:
				print("No previous item, removing from slot")
				slot_data.remove_items(1)
			update_slot(slot_data)

func _on_right_click() -> void:
	if slot_data and slot_data.item:
		if slot_data.item.type == ItemData.ItemType.CONSUMABLE:
			# Handle consumable use here
			slot_data.remove_items(1)
			update_slot(slot_data)
