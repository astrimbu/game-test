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
	
	# Connect to EventBus signals
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.game_state_reset.connect(_on_game_state_reset)
	
	# Update all slots
	update_inventory()
	
	# Toggle visibility with 'I' key
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		visible = !visible

func _on_item_picked_up(_item: ItemData) -> void:
	update_inventory()

func _on_game_state_reset() -> void:
	print("InventoryUI: Handling game state reset")
	update_inventory()

func update_inventory() -> void:
	print("\nInventory Contents:")
	for i in range(GameState.player_data.inventory.size()):
		var slot = GameState.player_data.inventory[i]
		if slot.item:
			print("Slot ", i, ": ", slot.item.name, " (", slot.amount, ")")
		else:
			print("Slot ", i, ": empty")
	
	for i in range(slots.size()):
		slots[i].update_slot(GameState.player_data.inventory[i])
