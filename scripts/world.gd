extends Node

func _ready():
	for enemy in get_tree().get_nodes_in_group("enemies"):  # Assuming enemies are in this group
		enemy.enemy_died.connect(_on_enemy_died)
		enemy.enemy_respawned.connect(_on_enemy_respawned)

func _on_enemy_died(enemy: Enemy):
	# Do any level-wide processing when an enemy dies
	print("Enemy died at: ", enemy.global_position)

func _on_enemy_respawned(enemy: Enemy):
	# Do any level-wide processing when an enemy respawns
	print("Enemy respawned at: ", enemy.global_position) 
