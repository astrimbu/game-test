extends Control

@onready var resume_button = $CenterContainer/VBoxContainer/ResumeButton
@onready var save_button = $CenterContainer/VBoxContainer/SaveButton
@onready var reset_button = $CenterContainer/VBoxContainer/ResetButton

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	
	# Hide by default
	hide()

func _on_resume_pressed() -> void:
	EventBus.toggle_pause.emit()

func _on_save_pressed() -> void:
	SaveManager.save_game()

func _on_reset_pressed() -> void:
	EventBus.reset_game_state()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		EventBus.toggle_pause.emit()
