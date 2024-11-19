extends Node

@onready var QuestDatabase = $QuestDatabase
@onready var SaveManager = $SaveManager

var available_quests = {}
var active_quests = {}
var completed_quests = {}

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
		available_quests[quest_id] = quest
	else:
		print("Quest not found in database: ", quest_id)

func start(quest_id):
	if quest_id in available_quests:
		active_quests[quest_id] = available_quests[quest_id]
		available_quests.erase(quest_id)
		emit_signal("quest_started", quest_id)
		emit_signal("quest_updated", quest_id, active_quests[quest_id].get_current_objective())

func update(quest_id):
	if quest_id in active_quests:
		var quest = active_quests[quest_id]
		var is_complete = quest.advance_objective()
		if is_complete:
			complete(quest_id)
		else:
			emit_signal("quest_updated", quest_id, quest.get_current_objective())

func complete(quest_id):
	if quest_id in active_quests:
		completed_quests[quest_id] = active_quests[quest_id]
		active_quests.erase(quest_id)
		SaveManager.update_quest_state(quest_id, true)
		emit_signal("quest_completed", quest_id)

func fail(quest_id):
	if quest_id in active_quests:
		available_quests[quest_id] = active_quests[quest_id]
		active_quests.erase(quest_id)
