extends Control

@onready var resources_ui = $ResourcesUI
@onready var inventory_ui = $InventoryUI
@onready var inventory_button = $InventoryButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Make sure UI can process while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	inventory_ui.visible = false
	
	# Connect inventory button
	inventory_button.pressed.connect(_on_inventory_button_pressed)

func _on_inventory_button_pressed() -> void:
	inventory_ui.toggle_inventory()

# If you need to update both resources and inventory
func refresh_ui() -> void:
	resources_ui.refresh()
	inventory_ui.update_inventory()
