extends Node

const SAVE_FILE = "user://game_save.dat"

var game_state = {
	"quests": {
		"completed": [],
		"active": []
	},
	"portals": {},
	"cookies": {},
	"player": {
		"position": {"x": 0.0, "y": 0.0},
		"current_scene": ""
	}
}

func _ready():
	load_game()

func save_game():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_var(game_state)
		file.close()

func load_game():
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		if file:
			game_state = file.get_var()
			file.close()

func update_quest_state(quest_id: String, completed: bool):
	if completed:
		if quest_id not in game_state["quests"]["completed"]:
			game_state["quests"]["completed"].append(quest_id)
		if quest_id in game_state["quests"]["active"]:
			game_state["quests"]["active"].erase(quest_id)
	else:
		if quest_id not in game_state["quests"]["active"]:
			game_state["quests"]["active"].append(quest_id)
	save_game()

func update_portal_state(portal_id: String, is_active: bool):
	game_state["portals"][portal_id] = is_active
	save_game()

func update_cookies_state(cookies_data: Dictionary):
	game_state["cookies"] = cookies_data
	save_game()

func update_player_state(position: Vector2, current_scene: String):
	game_state["player"]["position"] = {"x": position.x, "y": position.y}
	game_state["player"]["current_scene"] = current_scene
	save_game()

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in game_state["quests"]["completed"]

func is_portal_active(portal_id: String) -> bool:
	return game_state["portals"].get(portal_id, false)

func get_cookies_state() -> Dictionary:
	return game_state.get("cookies", {})

func get_player_state():
	return game_state["player"]
