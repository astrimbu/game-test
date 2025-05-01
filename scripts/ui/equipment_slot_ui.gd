class_name EquipmentSlotUI
extends Panel

@onready var item_icon: TextureRect = $ItemIcon
@onready var slot_label: Label = $SlotLabel

var current_item: ItemData
var slot_type: String # e.g., "head", "weapon"
var ui_reference: Control # Assuming this is set elsewhere

func _ready() -> void:
	InventoryManager.equipment_updated.connect(_on_equipment_updated)

func _on_equipment_updated(updated_slot: String, item: ItemData) -> void:
	# Check if the update signal is for this specific equipment slot
	if updated_slot == slot_type:
		update_slot(item)

func setup(type: String, label_text: String) -> void:
	slot_type = type
	slot_label.text = label_text
	# Optionally, fetch the initial item for this slot
	update_slot(InventoryManager.get_equipped_item(slot_type))

func update_slot(item: ItemData) -> void:
	current_item = item
	
	# Reset position before applying new offset
	item_icon.position = Vector2.ZERO 
	
	if current_item:
		item_icon.texture = current_item.icon
		# Apply offset directly from ItemData
		item_icon.position = current_item.ui_icon_offset 
	else:
		item_icon.texture = null

func _get_drag_data(_position: Vector2) -> Variant:
	if not current_item:
		return null
		
	# Create drag preview
	var preview = TextureRect.new()
	preview.texture = current_item.icon
	# Apply offset to preview as well? Maybe not needed if centered.
	# preview.position = current_item.ui_icon_offset
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.custom_minimum_size = Vector2(48, 48) # Or derive from slot size
	
	# Center the preview on the mouse
	var control = Control.new()
	control.add_child(preview)
	preview.position = -preview.custom_minimum_size / 2
	control.z_index = 100 # Ensure preview is on top
	
	set_drag_preview(control)
	
	return {
		"source": self,
		"item": current_item,
		"slot_type": slot_type # Identify source slot type
	}

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("item")):
		return false
	
	var item_to_drop: ItemData = data.get("item")
	if not item_to_drop: return false

	# Check if the item being dropped is equipment and matches this slot type
	return item_to_drop.type == ItemData.ItemType.EQUIPMENT and item_to_drop.equip_slot == slot_type

func _drop_data(_position: Vector2, data: Variant) -> void:
	var source_slot = data.get("source")
	if source_slot == self: return # Dropping onto itself

	var item_to_equip: ItemData = data.get("item")
	if not item_to_equip: return

	if source_slot is EquipmentSlotUI:
		# Swap items between two equipment slots (if types match)
		# This requires more complex logic in InventoryManager (e.g., InventoryManager.swap_equipment)
		print("Attempting equipment swap (requires InventoryManager logic)")
		# Example conceptual call:
		# InventoryManager.swap_equipment(source_slot.slot_type, self.slot_type)
	elif source_slot is InventorySlotUI:
		# Equip item from inventory
		var source_inventory_index = data.get("slot_index", -1)
		if source_inventory_index != -1:
			InventoryManager.equip_item(item_to_equip, source_inventory_index)
	else:
		printerr("Unknown drop source: ", source_slot)


# --- Input Handling --- (Keep existing input functions)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				# Unequip item on left click if not dragging
				if not get_viewport().gui_is_dragging():
					unequip_item()
			# Add right-click handling if needed (e.g., item details)

func unequip_item() -> void:
	# Trigger unequip only if there is an item in this slot
	if current_item:
		# Ask InventoryManager to unequip the item from this slot type
		# Let InventoryManager decide where it goes (find first empty inventory slot)
		InventoryManager.unequip_item(slot_type)
