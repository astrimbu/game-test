extends Control

@onready var resources_ui = $ResourcesUI
@onready var inventory_ui = $InventoryUI
@onready var equipment_ui = $EquipmentUI
@onready var pause_ui = $PauseUI
@onready var inventory_button = $InventoryButton
@onready var pause_button = $PauseButton

func _ready() -> void:
	# Make sure UI can process while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Hide UI elements by default
	inventory_ui.visible = false
	equipment_ui.visible = false
	pause_ui.visible = false
	
	# Connect signals
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	EventBus.toggle_pause.connect(_on_toggle_pause)

func _on_inventory_button_pressed() -> void:
	toggle_inventory()

func _on_pause_button_pressed() -> void:
	EventBus.toggle_pause.emit()

func toggle_inventory() -> void:
	inventory_ui.toggle_visibility()
	equipment_ui.toggle_visibility()

func _on_toggle_pause() -> void:
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	pause_ui.visible = is_paused

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_pause"):
		EventBus.toggle_pause.emit()

func refresh_ui() -> void:
	resources_ui.refresh()
	inventory_ui.update_inventory()
