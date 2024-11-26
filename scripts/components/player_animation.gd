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
	
	var combat = get_parent().get_node("Combat")
	if combat:
		combat.started_shooting.connect(_on_started_shooting)
		combat.stopped_shooting.connect(_on_stopped_shooting)

func _on_jumped() -> void:
	animation_player.play("jump")

func _on_started_moving() -> void:
	animation_player.play("walk")

func _on_stopped_moving() -> void:
	if not animation_player.current_animation in ["shoot", "jump"]:
		animation_player.play("idle")

func _on_started_shooting() -> void:
	animation_player.play("shoot")

func _on_stopped_shooting() -> void:
	animation_player.play("idle")

func flip_sprite(direction: float) -> void:
	if direction != 0:
		sprite.scale.x = -1 if direction < 0 else 1 