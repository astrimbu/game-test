extends NPC

func _init_npc():
	npc_name = "Shopkeeper"
	current_dialogue = "shop"

func start_interaction():
	# Custom shop interaction logic
	emit_signal("dialogue_started", npc_name, current_dialogue)