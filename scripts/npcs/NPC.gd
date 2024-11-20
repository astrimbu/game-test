extends CharacterBody2D
class_name NPC

signal dialogue_started(npc_name: String, dialogue_id: String)
signal quest_available(quest_id: String)
signal quest_completed(quest_id: String)

@export var npc_name: String = "Unknown"
@export var interaction_radius: float = 100.0
@export var available_quests: Array[String] = []
@export var current_dialogue: String = "default"

# Required node paths
@export var sprite_path: NodePath
@export var animation_player_path: NodePath

# Onready vars using the paths
@onready var sprite = get_node(sprite_path)
@onready var animation_player = get_node(animation_player_path)

var can_interact: bool = false
var player_ref: CharacterBody2D = null

func _ready():
	# Validate required nodes
	assert(sprite != null, "Sprite node not found at specified path")
	assert(animation_player != null, "AnimationPlayer node not found at specified path")
	
	add_to_group("npc")
	_init_npc()

# Virtual method for child classes to override
func _init_npc():
	pass

# Check if a position is within interaction radius
func is_within_interaction_radius(pos: Vector2) -> bool:
	return global_position.distance_to(pos) <= interaction_radius

# Virtual method for child classes to override
func start_interaction():
	pass
