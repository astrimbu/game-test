extends CharacterBody2D

signal dialogue_started(npc_name: String, dialogue_id: String)
signal quest_available(quest_id: String)
signal quest_completed(quest_id: String)

@export var npc_name: String = "Unknown"
@export var interaction_radius: float = 100.0
@export var available_quests: Array[String] = []
@export var current_dialogue: String = "default"

@onready var interaction_area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D

var active_quests: Array[String] = []
var completed_quests: Array[String] = []
var can_interact: bool = false
var player_ref: CharacterBody2D = null

func _ready():
	# Set up interaction area
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	add_to_group("npc")

func _unhandled_input(event):
	if not can_interact:
		return
		
	if event.is_action_pressed("interact"):  # Add this action in Project Settings
		start_interaction()

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):  # Add player to this group
		can_interact = true
		player_ref = body

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		can_interact = false
		player_ref = null

func start_interaction():
	# Face the player
	if player_ref:
		sprite.flip_h = player_ref.global_position.x < global_position.x
	
	# Check for completeable quests first
	for quest_id in active_quests:
		if _can_complete_quest(quest_id):
			emit_signal("quest_completed", quest_id)
			active_quests.erase(quest_id)
			completed_quests.append(quest_id)
			return
	
	# Then check for available quests
	for quest_id in available_quests:
		if _can_start_quest(quest_id):
			emit_signal("quest_available", quest_id)
			return
	
	# If no quest interaction, start dialogue
	emit_signal("dialogue_started", npc_name, current_dialogue)

func _can_start_quest(quest_id: String) -> bool:
	# Add your quest prerequisites logic here
	return not active_quests.has(quest_id) and not completed_quests.has(quest_id)

func _can_complete_quest(quest_id: String) -> bool:
	# Add your quest completion requirements logic here
	return true

func set_dialogue(dialogue_id: String):
	current_dialogue = dialogue_id

func add_quest(quest_id: String):
	if not available_quests.has(quest_id):
		available_quests.append(quest_id)

func start_quest(quest_id: String):
	if available_quests.has(quest_id):
		active_quests.append(quest_id)
		available_quests.erase(quest_id)
