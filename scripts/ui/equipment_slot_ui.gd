class_name EquipmentSlotUI
extends Panel

@onready var item_icon: TextureRect = $ItemIcon
@onready var slot_label: Label = $SlotLabel

var slot_type: String = ""  # "weapon", "head", etc.
var current_item: ItemData = null
var ui_reference: Control = null

func _ready() -> void:
	# Connect to equipment change events
	EventBus.equipment_changed.connect(_on_equipment_changed)

func setup(type: String, label: String) -> void:
	slot_type = type
	slot_label.text = label
	# Get UI reference from parent EquipmentUI
	ui_reference = get_parent().get_parent().ui
	# Check if there's already an item equipped
	var equipped_item = GameState.player_data.equipment.get(slot_type)
	if equipped_item:
		update_slot(equipped_item)

func update_slot(item: ItemData = null) -> void:
	current_item = item
	if item:
		item_icon.texture = item.icon
		item_icon.visible = true
	else:
		item_icon.texture = null
		item_icon.visible = false

func _on_equipment_changed(slot: String, item: ItemData) -> void:
	if slot == slot_type:
		update_slot(item)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				unequip_item()

func unequip_item() -> void:
	if current_item:
		var removed_item = GameState.player_data.unequip_item(slot_type)
		if removed_item:
			# Try to add to inventory
			var remaining = GameState.player_data.add_item(removed_item)
			if remaining == 0:
				EventBus.publish_equipment_changed(slot_type, null)
				if ui_reference:
					ui_reference.refresh_ui()
