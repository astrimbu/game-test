extends Control

@onready var resources_ui = $ResourcesUI
@onready var inventory_ui = $InventoryUI
@onready var equipment_ui = $EquipmentUI
@onready var inventory_button = $InventoryButton

func _ready() -> void:
	# Make sure UI can process while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	inventory_ui.visible = false
	equipment_ui.visible = false
	inventory_button.pressed.connect(_on_inventory_button_pressed)

func _on_inventory_button_pressed() -> void:
	toggle_inventory()

func toggle_inventory() -> void:
	inventory_ui.toggle_visibility()
	equipment_ui.toggle_visibility()

func refresh_ui() -> void:
	resources_ui.refresh()
	inventory_ui.update_inventory()
