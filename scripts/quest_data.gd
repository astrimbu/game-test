extends Resource
class_name QuestData

@export var id: String
@export var name: String
@export var description: String
@export var objectives: Array[String]
@export var reward: Dictionary

func _init(p_id: String = "", p_name: String = "", p_description: String = "", p_objectives: Array[String] = [], p_reward: Dictionary = {}):
	id = p_id
	name = p_name
	description = p_description
	objectives = p_objectives
	reward = p_reward
