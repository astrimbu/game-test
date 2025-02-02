extends Control

@export var slot_scene: PackedScene
@export var grid_container: GridContainer

var slots: Array[InventorySlotUI] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create inventory slots
	for i in range(GameState.player_data.inventory_size):
		var slot = slot_scene.instantiate() as InventorySlotUI
		grid_container.add_child(slot)
		slot.slot_index = i
		slots.append(slot)
	
	# Update all slots
	update_inventory()
	
	# Toggle visibility with 'I' key
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		visible = !visible

func update_inventory() -> void:
	for i in range(slots.size()):
		slots[i].update_slot(GameState.player_data.inventory[i])
