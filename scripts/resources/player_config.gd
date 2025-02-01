class_name PlayerConfig
extends Resource

# Movement
@export_group("Movement")
@export var SPEED := 200.0
@export var JUMP_VELOCITY := -350.0
@export var ACCELERATION := 1000.0
@export var FRICTION := 1000.0
@export var AIR_RESISTANCE := 200.0

# Platform Detection
@export_group("Platform Detection")
@export var DROP_THROUGH_DURATION := 0.2
@export var DROP_CHECK_DISTANCE := 400.0
@export var JUMP_CHECK_DISTANCE := 100.0
@export var JUMP_POSITION_TOLERANCE := 20.0

# Interaction
@export_group("Interaction")
@export var INTERACTION_DISTANCE := 86.0
@export var RAY_LENGTH := 200.0
@export var RAY_ANGLES: Array[float] = [0.0, 15.0, 30.0, 45.0, 60.0]

# Stats that might be affected by equipment
func get_modified_speed() -> float:
	var base = SPEED
	# Later we'll add equipment/status modifiers from GameState
	return base

func get_modified_jump() -> float:
	var base = JUMP_VELOCITY
	# Later we'll add equipment/status modifiers from GameState
	return base
