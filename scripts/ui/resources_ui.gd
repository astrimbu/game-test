extends MarginContainer

@onready var xp_label = $HBoxContainer/XPLabel
@onready var coins_label = $HBoxContainer/CoinsContainer/CoinsLabel
@onready var level_label = $HBoxContainer/LevelLabel

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.resources.xp_changed.connect(_on_xp_changed)
		player.resources.coins_changed.connect(_on_coins_changed)
		player.resources.level_up.connect(_on_level_up)

func _on_xp_changed(new_xp: int) -> void:
	xp_label.text = "XP: %d" % new_xp

func _on_coins_changed(new_coins: int) -> void:
	coins_label.text = "%d" % new_coins

func _on_level_up(new_level: int) -> void:
	level_label.text = "Level: %d" % new_level
