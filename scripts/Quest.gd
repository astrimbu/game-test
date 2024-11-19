class_name Quest
extends Resource

var id: String
var name: String
var description: String
var objectives: Array[String]
var current_objective: int = 0
var reward: Dictionary

func _init(p_id: String, p_name: String, p_description: String, p_objectives: Array[String], p_reward: Dictionary):
	id = p_id
	name = p_name
	description = p_description
	objectives = p_objectives
	reward = p_reward

func advance_objective() -> bool:
	current_objective += 1
	return current_objective >= objectives.size()

func get_current_objective() -> String:
	return objectives[current_objective] if current_objective < objectives.size() else ""
