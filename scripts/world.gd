extends Node

# Reference to enemy scenes
var enemy_scenes = {
	"bat": preload("res://scenes/enemy/BatEnemy.tscn"),
	# Add other enemy types here
}

func _ready() -> void:
	# Connect to EventBus signals
	EventBus.enemy_respawn_requested.connect(_on_enemy_respawn_requested)

func _on_enemy_respawn_requested(enemy_type: String, position: Vector2) -> void:
	if enemy_scenes.has(enemy_type):
		var enemy_scene = enemy_scenes[enemy_type]
		var enemy = enemy_scene.instantiate()
		enemy.global_position = position
		add_child(enemy)
		EventBus.publish_enemy_spawned(enemy, position)
