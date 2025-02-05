extends Control

@export var slot_scene: PackedScene
@onready var grid_container: GridContainer = $Slots

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
		slots[slot_id] = slot
	
	# Hide by default
	visible = false

func toggle_visibility() -> void:
	visible = !visible

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		toggle_visibility()
	elif event.is_action_pressed("ui_cancel") and visible:
		hide()
