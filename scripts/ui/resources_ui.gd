extends MarginContainer

@onready var level_label = $VBoxContainer/HBoxContainer/LevelLabel
@onready var xp_label = $VBoxContainer/HBoxContainer/XPContainer/XPLabel
@onready var xp_fill = $VBoxContainer/HBoxContainer/XPContainer/Background/Fill
@onready var coins_label = $VBoxContainer/HBoxContainer/CoinsContainer/CoinsLabel

var current_level: int = 1
var level_progress: int = 0
var max_xp: int = 10

func _ready() -> void:
	# Get initial state
	current_level = GameState.player_data.level
	level_progress = GameState.player_data.xp
	max_xp = current_level * 100
	
	# Update UI with initial state
	level_label.text = "Lvl: %d" % current_level
	_update_xp_bar()
	coins_label.text = str(GameState.player_data.coins)
	
	# Connect to EventBus signals instead of direct node signals
	EventBus.xp_gained.connect(_on_xp_changed)
	EventBus.coins_gained.connect(_on_coins_changed)
	EventBus.level_up.connect(_on_level_up)

func _on_xp_changed(_amount: int) -> void:
	level_progress = GameState.player_data.xp  # Get the total XP from GameState
	_update_xp_bar()

func _on_coins_changed(new_coins: int) -> void:
	coins_label.text = str(new_coins)

func _on_level_up(new_level: int) -> void:
	current_level = new_level
	max_xp = current_level * 100
	level_label.text = "Lvl: %d" % current_level
	_update_xp_bar()

func _update_xp_bar() -> void:
	var fill_amount = float(level_progress) / max_xp
	xp_fill.scale.x = fill_amount
	xp_label.text = "%d/%d XP" % [level_progress, max_xp]
