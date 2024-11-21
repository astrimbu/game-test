extends NPC

func _init_npc():
	npc_name = "Squiddy"
	available_quests = ["intro_quest"]
	current_dialogue = "welcome"

func start_interaction():
	if available_quests.size() > 0:
		emit_signal("quest_available", available_quests[0])
	emit_signal("dialogue_started", npc_name, current_dialogue)
