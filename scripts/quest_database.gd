extends Node

var quests = {
	"intro_quest": QuestData.new(
		"intro_quest",
		"Intro Quest",
		"Help WelcomeBot with a simple task",
		QuestData.QuestType.TALK,
		[
			"Talk to WelcomeBot",
			"Go to the other side of the map",
			"Return to WelcomeBot"
		],
		{"experience": 50, "gold": 100},
		1,  # required_level
		[]   # required_quests
	),
	"quest2": QuestData.new(
		"quest2",
		"Quest2",
		"There isn't a second quest yet",
		QuestData.QuestType.TALK,
		[
			"Talk to WelcomeBot2",
			"Wait for the quest to be finished",
			"Return to WelcomeBot2"
		],
		{"experience": 100, "gold": 500},
		2,  # required_level
		["intro_quest"]  # requires intro_quest to be completed
	)
}

func get_quest(quest_id: String) -> QuestData:
	return quests.get(quest_id)
