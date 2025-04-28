# Interaction System: Handles player interactions with enemies and objects
# Manages target acquisition, validation and combat engagement logic

extends Node

# Target Management:
# - Maintains list of valid interaction targets
# - Handles target validation and cleanup
# - Coordinates with combat system for attack targeting
var current_targets: Array[Node] = []
var current_target: Node = null

func clear_targets():
	# Clear all combat targets when:
	# 1. Enemy dies
	# 2. Player moves out of range
	# 3. Combat sequence completes
	# This prevents attacking invalid/dead targets
	current_targets.clear()
	current_target = null
	
	# Notify systems that depend on target state
	EventBus.targets_cleared.emit() 