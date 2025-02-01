extends Node

@onready var QuestDatabase = $QuestDatabase
@onready var SaveManager = $SaveManager

signal quest_started(quest_id)
signal quest_updated(quest_id, objective)
signal quest_completed(quest_id)

func add_from_database(quest_id: String):
	var quest_data = QuestDatabase.get_quest(quest_id)
	if quest_data:
		var quest = Quest.new(
			quest_data.id,
			quest_data.name,
			quest_data.description,
			quest_data.objectives,
			quest_data.reward
		)
		if quest_id not in GameState.world_state.completed_quests:
			GameState.world_state.active_quests.append(quest_id)
			emit_signal("quest_started", quest_id)
			emit_signal("quest_updated", quest_id, quest.get_current_objective())

func complete_quest(quest_id: String):
	if quest_id in GameState.world_state.active_quests:
		GameState.world_state.active_quests.erase(quest_id)
		GameState.world_state.completed_quests.append(quest_id)
		
		# Get quest data and apply rewards
		var quest_data = QuestDatabase.get_quest(quest_id)
		if quest_data and quest_data.reward:
			if quest_data.reward.has("experience"):
				GameState.player_data.xp += quest_data.reward.experience
				GameState.emit_resource_signal("xp_changed", GameState.player_data.xp)
			
			if quest_data.reward.has("gold"):
				GameState.player_data.coins += quest_data.reward.gold
				GameState.emit_resource_signal("coins_changed", GameState.player_data.coins)
		
		emit_signal("quest_completed", quest_id)

func is_quest_active(quest_id: String) -> bool:
	return quest_id in GameState.world_state.active_quests

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in GameState.world_state.completed_quests
