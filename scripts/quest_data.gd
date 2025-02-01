extends Resource
class_name QuestData

enum QuestType { KILL, COLLECT, TALK, EXPLORE }

@export var id: String
@export var name: String
@export var description: String
@export var type: QuestType
@export var objectives: Array[String]
@export var reward: Dictionary
@export var required_level: int = 1
@export var required_quests: Array[String] = []

func _init(p_id: String = "", p_name: String = "", p_description: String = "", 
           p_type: QuestType = QuestType.TALK, p_objectives: Array[String] = [], 
           p_reward: Dictionary = {}, p_required_level: int = 1, 
           p_required_quests: Array[String] = []):
    id = p_id
    name = p_name
    description = p_description
    type = p_type
    objectives = p_objectives
    reward = p_reward
    required_level = p_required_level
    required_quests = p_required_quests

func is_available() -> bool:
    # Check if player meets level requirement
    if GameState.player_data.level < required_level:
        return false
    
    # Check if required quests are completed
    for quest_id in required_quests:
        if quest_id not in GameState.world_state.completed_quests:
            return false
    
    return true
