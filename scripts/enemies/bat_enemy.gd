extends Enemy

func _init_enemy():
	# Configure bat-specific properties
	max_health = 3
	damage_per_hit = 1
	xp_value = 1
	coin_value = 1
	
	# Node paths
	sprite_path = "Sprite2D"
	animation_player_path = "AnimationPlayer"
	health_bar_path = "HealthBar"
