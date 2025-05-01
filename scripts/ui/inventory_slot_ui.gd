class_name InventorySlotUI
extends Panel

@onready var item_icon: TextureRect = $ItemIcon
@onready var quantity_label: Label = $QuantityLabel

var slot_data: InventorySlot
var ui_reference: Control

func _ready() -> void:
	InventoryManager.inventory_updated.connect(_on_inventory_updated)

func _on_inventory_updated() -> void:
	if slot_data:
		update_slot(slot_data)

func update_slot(new_slot_data: InventorySlot) -> void:
	slot_data = new_slot_data
	
	# Reset icon position first
	item_icon.position = Vector2.ZERO # Default position

	if slot_data and slot_data.item:
		item_icon.texture = slot_data.item.icon
		
		# Apply offset from ItemData
		item_icon.position = slot_data.item.ui_icon_offset 

		if slot_data.amount > 1:
			quantity_label.text = str(slot_data.amount)
			quantity_label.show()
		else:
			quantity_label.hide()
	else:
		item_icon.texture = null
		quantity_label.hide()

func _get_drag_data(_position: Vector2) -> Variant:
	if not slot_data or not slot_data.item:
		return null
		
	# Create drag preview
	var preview = TextureRect.new()
	preview.texture = slot_data.item.icon
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.custom_minimum_size = Vector2(48, 48)
	
	# Center the preview on the mouse
	var control = Control.new()
	control.add_child(preview)
	preview.position = -preview.custom_minimum_size / 2
	control.z_index = 100
	
	set_drag_preview(control)
	
	return {
		"source": self,
		"item": slot_data.item,
		"slot_data": slot_data,
		"slot_index": InventoryManager.get_inventory_slot_index(slot_data)
	}

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("item")):
		return false
	
	# If coming from inventory, allow any drop
	if not (data["source"] is EquipmentSlotUI):
		return true
		
	# For equipment drops, apply restrictions
	if not slot_data or not slot_data.item:
		return true
		
	return slot_data.item.type == ItemData.ItemType.EQUIPMENT and slot_data.item.equip_slot == data["item"].equip_slot

func _drop_data(_position: Vector2, data: Variant) -> void:
	var source_slot = data["source"]
	
	if source_slot == self:
		return
		
	if source_slot is EquipmentSlotUI:
		InventoryManager.unequip_item(source_slot.slot_type, InventoryManager.get_inventory_slot_index(slot_data))
	else:
		var from_index = data["slot_index"]
		var to_index = InventoryManager.get_inventory_slot_index(slot_data)
		InventoryManager.move_inventory_item(from_index, to_index)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if not get_viewport().gui_is_dragging():
					_on_left_click()
			MOUSE_BUTTON_RIGHT:
				_on_right_click()

func _on_left_click() -> void:
	if slot_data and slot_data.item:
		if slot_data.item.type == ItemData.ItemType.EQUIPMENT:
			var slot_index = InventoryManager.get_inventory_slot_index(slot_data)
			InventoryManager.equip_item(slot_data.item, slot_index)

func _on_right_click() -> void:
	if slot_data and slot_data.item:
		if slot_data.item.type == ItemData.ItemType.CONSUMABLE:
			slot_data.remove_items(1)
			update_slot(slot_data)
