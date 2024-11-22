extends MarginContainer

@onready var xp_fill = $VBoxContainer/HBoxContainer/XPContainer/Background/Fill
@onready var xp_label = $VBoxContainer/HBoxContainer/XPContainer/XPLabel
@onready var coins_label = $VBoxContainer/HBoxContainer/CoinsContainer/CoinsLabel
@onready var level_label = $VBoxContainer/HBoxContainer/LevelLabel
@onready var player = get_tree().get_first_node_in_group("player")

var max_xp: int = 10  # Base XP needed for first level
var total_xp: int = 0  # Track total XP earned
var level_progress: int = 0  # Track XP progress toward next level
var current_level: int = 1

func _ready() -> void:
	if player:
		player.resources.xp_changed.connect(_on_xp_changed)
		player.resources.coins_changed.connect(_on_coins_changed)
		player.resources.level_up.connect(_on_level_up)
		_update_xp_bar()

func _on_xp_changed(xp_gained: int) -> void:
	print("XP gained: %d" % xp_gained)
	print("Total XP: %d" % total_xp)
	print("Level progress: %d" % level_progress)
	total_xp += xp_gained
	level_progress += xp_gained
	
	# Check for level up
	if level_progress >= max_xp:
		_level_up()
	
	_update_xp_bar()

func _level_up() -> void:
	current_level += 1
	# Reset progress toward next level
	level_progress = 0
	# Increase XP required for next level
	max_xp = 10 * current_level
	# Update level display
	level_label.text = "Lvl: %d" % current_level

func _update_xp_bar() -> void:
	# Calculate fill amount (0.0 to 1.0)
	var fill_amount = float(level_progress) / max_xp
	# Update the fill sprite's scale
	xp_fill.scale.x = fill_amount
	# Update the XP label
	xp_label.text = "%d/%d XP" % [level_progress, max_xp]

func _on_coins_changed(new_coins: int) -> void:
	coins_label.text = "%d" % new_coins

func _on_level_up(new_level: int) -> void:
	level_label.text = "Lvl: %d" % new_level
