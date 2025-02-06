extends Control

@export var slot_scene: PackedScene
@onready var grid_container: GridContainer = $Slots
@onready var ui = get_parent()

var slots: Dictionary = {}
var EQUIPMENT_SLOTS = {
	"weapon": "Weapon",
	"head": "Head",
	"chest": "Chest",
	# Add more slots as needed
}

func _ready() -> void:
	# Create equipment slots
	for slot_id in EQUIPMENT_SLOTS:
		var slot = slot_scene.instantiate() as EquipmentSlotUI
		grid_container.add_child(slot)
		slot.setup(slot_id, EQUIPMENT_SLOTS[slot_id])
		slot.ui_reference = get_parent()
		slots[slot_id] = slot
	
	# Connect to game state reset
	EventBus.game_state_reset.connect(_on_game_state_reset)
	
	# Hide by default
	visible = false

func _on_game_state_reset() -> void:
	print("EquipmentUI: Handling game state reset")
	# Clear all equipment slots
	for slot in slots.values():
		slot.update_slot(null)

func toggle_visibility() -> void:
	visible = !visible

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		toggle_visibility()
	elif event.is_action_pressed("ui_cancel") and visible:
		hide()
