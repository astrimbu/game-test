class_name WalkingState
extends PlayerState

func enter_state(player: CharacterBody2D) -> void:
	player.animation_player.play("walk")

func update_state(player: CharacterBody2D, delta: float) -> void:
	apply_gravity(player, delta)
	
	if not player.is_on_floor():
		player.set_state("idle")
		return
	
	var direction = Input.get_axis("ui_left", "ui_right")
	player.movement.move(direction)
	
	if direction == 0:
		player.set_state("idle")
		return
	
	if Input.is_action_pressed("ui_up") and player.has_platform_above():
		player.set_state("jumping")
		return
	
	player.move_and_slide()