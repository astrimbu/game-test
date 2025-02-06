class_name EquipmentSlotUI
extends Panel

@onready var item_icon: TextureRect = $ItemIcon
@onready var slot_label: Label = $SlotLabel

var current_item: ItemData
var slot_type: String
var ui_reference: Control

func _ready() -> void:
	InventoryManager.equipment_updated.connect(_on_equipment_updated)

func _on_equipment_updated(updated_slot: String, item: ItemData) -> void:
	if updated_slot == slot_type:
		update_slot(item)

func setup(type: String, label: String) -> void:
	slot_type = type
	slot_label.text = label

func update_slot(item: ItemData) -> void:
	current_item = item
	if current_item:
		item_icon.texture = current_item.icon
	else:
		item_icon.texture = null

func _get_drag_data(_position: Vector2) -> Variant:
	if not current_item:
		return null
		
	# Create drag preview
	var preview = TextureRect.new()
	preview.texture = current_item.icon
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
		"item": current_item,
		"slot_type": slot_type
	}

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("item")):
		return false
	
	var item = data["item"]
	return item.type == ItemData.ItemType.EQUIPMENT and item.equip_slot == slot_type

func _drop_data(_position: Vector2, data: Variant) -> void:
	var source_slot = data["source"]
	
	if source_slot == self:
		return
		
	if source_slot is EquipmentSlotUI:
		# Equipment to equipment swap
		var from_slot = data["slot_type"]
		var to_slot = slot_type
		# Handle through InventoryManager later if needed
	else:
		# Inventory to equipment
		var source_index = data["slot_index"]
		InventoryManager.equip_item(data["item"], source_index)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if not get_viewport().gui_is_dragging():
					unequip_item()

func unequip_item() -> void:
	if current_item:
		InventoryManager.unequip_item(slot_type)
