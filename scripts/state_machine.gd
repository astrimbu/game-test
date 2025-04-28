# State Machine: Manages player character states and transitions
# Handles combat, movement, and interaction state changes
#
# Available States:
# - Idle: Default state, character at rest
# - Walk: Basic movement state
# - Run: Faster movement state
# - Jump: Aerial movement state
# - Attack: Combat offensive state
# - Block: Combat defensive state
# - Interact: Handles object/NPC interactions
#
# State Structure:
# - Each state is a child node
# - States must implement enter(), exit(), and process() functions
# - States handle their own animations and physics
# - Transitions are managed through the transition_to() function

extends Node

# Reference to the current active state
var current_state: Node = null

# ... existing code ...

# State Transition Logic:
# - Each state handles its own exit conditions
# - Combat states (Attack, Block) complete their animations before transitioning
# - Idle state is the default fallback when no other state is active
func transition_to(new_state: String) -> void:
	# Validate state exists
	if not has_node(new_state):
		return
		
	# Allow current state to clean up
	if current_state:
		current_state.exit()
	
	# Update state reference and enter new state
	current_state = get_node(new_state)
	current_state.enter()
	
	# Notify systems of state change
	EventBus.state_changed.emit(new_state)

# Initialize state machine by setting default state
func _ready() -> void:
	# Start in Idle state if it exists
	if has_node("Idle"):
		transition_to("Idle")

# Process current state
func _process(delta: float) -> void:
	if current_state:
		current_state.process(delta)

# ... existing code ...