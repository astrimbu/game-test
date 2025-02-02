class_name PlayerAnimation
extends Node

@export var animation_player: AnimationPlayer
@export var sprite: Sprite2D

func _ready() -> void:
	# Connect to relevant signals from other components
	var movement = get_parent().get_node("Movement")
	if movement:
		movement.jumped.connect(_on_jumped)
		movement.started_moving.connect(_on_started_moving)
		movement.stopped_moving.connect(_on_stopped_moving)
	
	# Use EventBus for combat animations
	EventBus.combat_animation_started.connect(_on_combat_animation_started)
	EventBus.combat_animation_ended.connect(_on_combat_animation_ended)

func _on_jumped() -> void:
	animation_player.play("jump")

func _on_started_moving() -> void:
	animation_player.play("walk")

func _on_stopped_moving() -> void:
	if not animation_player.current_animation in ["shoot", "jump"]:
		animation_player.play("idle")

func _on_combat_animation_started(animation_name: String) -> void:
	animation_player.play(animation_name)

func _on_combat_animation_ended(animation_name: String) -> void:
	animation_player.play("idle")

func flip_sprite(direction: float) -> void:
	if direction != 0:
		sprite.scale.x = -1 if direction < 0 else 1 
