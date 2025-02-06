extends Control

@export var slot_scene: PackedScene
@export var grid_container: GridContainer

var slots: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create inventory slots
	for i in range(GameState.player_data.inventory_size):
		var slot = slot_scene.instantiate()
		grid_container.add_child(slot)
		slot.ui_reference = get_parent()
		slots.append(slot)
	
	# Connect to inventory updates
	InventoryManager.inventory_updated.connect(_on_inventory_updated)
	
	# Hide by default
	visible = false
	
	# Initial refresh
	_on_inventory_updated()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		toggle_visibility()
	elif event.is_action_pressed("ui_cancel") and visible:
		hide()

func _on_inventory_updated() -> void:
	print("Refreshing inventory UI") # Debug line
	for i in range(slots.size()):
		slots[i].update_slot(GameState.player_data.inventory[i])

func toggle_visibility() -> void:
	visible = !visible
