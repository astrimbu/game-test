extends CharacterBody2D

@export var config: PlayerConfig

var current_state: PlayerState = null
var states: Dictionary = {}

# Components
@onready var movement: PlayerMovement = $Movement
@onready var combat: PlayerCombat = $Combat
@onready var interaction: PlayerInteraction = $Interaction
@onready var animation: PlayerAnimation = $Animation
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var target_indicator = $"../TargetIndicator"
@onready var resources: PlayerResources = $Resources
@onready var weapon_sprite: Sprite2D = $WeaponSprite
@onready var hat_sprite: Sprite2D = $HatSprite

# Forward some commonly accessed properties to keep state code cleaner
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_attacking: bool:
	get: return combat.is_attacking
	set(value): combat.is_attacking = value
var target_enemy: CharacterBody2D:
	get: return combat.target_enemy
	set(value): 
		print("PLAYER target_enemy SETTER called with: ", value.name if value else "NULL")
		if combat:  # Make sure combat component exists
			combat.target_enemy = value  # Directly set the property to avoid any side effects
			# Don't call combat.set_target(value) as that may have side effects
var target_position: Vector2:
	get: return interaction.target_position
	set(value): 
		# Maybe remove this setter later if states manage target_position directly
		interaction.target_position = value
		# interaction.set_movement_target(value) # Removed this call
var target_npc: CharacterBody2D:
	get: return interaction.target_npc
	# Add a setter if Player needs to manage this directly
	# set(value): interaction.target_npc = value
var last_direction: float:
	get: return movement.last_direction
var can_drop_through: bool:
	get: return movement.can_drop_through
	set(value): movement.can_drop_through = value

func _ready():
	add_to_group("player")
	
	# Ensure components are properly initialized with config
	movement.character = self
	movement.config = config
	combat.character = self
	combat.config = config
	interaction.character = self
	interaction.config = config
	# interaction.target_indicator = target_indicator # Interaction keeps its own reference
	
	# Initialize states (updated names and new states)
	states = {
		"idle": IdleState.new(),
		"moving": MovingState.new(), # Renamed from walking or moving_to_target
		"manual_moving": ManualMovingState.new(), # NEW state for keyboard
		"jumping": JumpingState.new(),
		"approaching_enemy": ApproachingEnemyState.new(), # New
		"approaching_npc": ApproachingNPCState.new(), # New
		"attacking": AttackingState.new() # Renamed from punching
		# "shooting": ShootingState.new(), # Removed for now
		# "moving_to_target": MovingToTargetState.new() # Removed/Renamed
	}
	
	# Connect component signals (including new interaction intents)
	_connect_component_signals()
	
	# Start in idle state
	set_state("idle")
	
	# Initial equipment check (AFTER connecting signals)
	# This handles cases where equipment is already set in GameState
	# before the player node is fully ready and connected to signals.
	var initial_weapon = GameState.player_data.equipment.get("weapon")
	if initial_weapon:
		_on_equipment_updated("weapon", initial_weapon)
	else:
		# Ensure weapon sprite is hidden if no initial weapon
		if weapon_sprite:
			weapon_sprite.visible = false
			
	var initial_hat = GameState.player_data.equipment.get("head")
	if initial_hat:
		_on_equipment_updated("head", initial_hat)
	else:
		# Ensure hat sprite is hidden if no initial hat
		if hat_sprite:
			hat_sprite.visible = false

func _connect_component_signals() -> void:
	# Movement signals
	movement.jumped.connect(func(): animation_player.play("jump"))
	movement.started_moving.connect(func(): animation_player.play("walk"))
	movement.stopped_moving.connect(func(): 
		# ADDED CHECK: Only play idle if we are NOT in AttackingState 
		# AND combat component also says we are not attacking.
		# This prevents interrupting the end of an attack animation.
		if not (current_state is AttackingState) and not is_attacking:
			animation_player.play("idle")
	)
	
	# Combat signals - use EventBus now
	EventBus.combat_animation_started.connect(func(anim_name: String): animation_player.play(anim_name))
	EventBus.combat_animation_ended.connect(func(anim_name: String): animation_player.play("idle"))
	
	# COMBAT STATE MANAGEMENT:
	# When an enemy dies, we need to handle state transitions carefully:
	# 1. Clear interaction targets immediately to prevent new attacks
	# 2. Only change state to idle if we're NOT in AttackingState
	# 3. Let AttackingState manage its own transition timing to ensure
	#    animations complete properly
	EventBus.enemy_killed.connect(func(enemy): 
		interaction.clear_targets()
		# Only change state if we're not in attacking state
		# Let the attacking state handle its own transition after animation
		if not (current_state is AttackingState):
			set_state("idle")
	)
	
	# Interaction signals (Originals - Review if still needed)
	# interaction.target_reached.connect(func(target):
	# 	if target is CharacterBody2D and target.has_method("start_interaction"):
	# 		target.start_interaction()
	# )
	
	# Connect NEW Interaction Intent Signals
	interaction.intent_move_to.connect(_on_intent_move_to)
	interaction.intent_attack.connect(_on_intent_attack)
	interaction.intent_interact.connect(_on_intent_interact)
	
	# Connect Inventory Manager signals
	InventoryManager.equipment_updated.connect(_on_equipment_updated)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.update_state(self, delta)

func _unhandled_input(event: InputEvent) -> void:
	# Always check for mouse clicks for interaction intents
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			handle_mouse_down(event.position)
		else: # Mouse button released
			handle_mouse_up(event.position)
		# Optionally, mark the event as handled if states shouldn't also process clicks
		# get_viewport().set_input_as_handled()
		# return # Uncomment return if states should NOT process clicks handled here
	
	# Allow current state to handle other inputs (or clicks if not handled above)
	if current_state:
		current_state.handle_input(self, event)

func set_state(new_state_name: String) -> void:
	if target_enemy:
		print("PLAYER set_state: ", new_state_name, " - target_enemy: ", combat.target_enemy.name if combat.target_enemy else "NULL")
	
	if current_state:
		current_state.exit_state(self)
	
	# Ensure the new state name exists before assigning
	if not states.has(new_state_name):
		printerr("Attempted to set invalid state: ", new_state_name)
		return # Or default to idle?
		
	current_state = states[new_state_name]
	current_state.enter_state(self)
	print("PLAYER after enter_state - target_enemy: ", combat.target_enemy.name if combat.target_enemy else "NULL")

# Delegate methods to components
func attack(is_auto: bool = false) -> void:
	combat.attack(is_auto)

# Split handle_click into two separate methods
func handle_mouse_down(clicked_pos: Vector2) -> void:
	interaction.handle_mouse_down(clicked_pos)

func handle_mouse_up(clicked_pos: Vector2) -> void:
	interaction.handle_mouse_up(clicked_pos)

# Keep the original handle_click for backward compatibility if needed
func handle_click(clicked_pos: Vector2) -> void:
	handle_mouse_down(clicked_pos)
	handle_mouse_up(clicked_pos)

func has_platform_above() -> bool:
	return movement.has_platform_above()

func has_platform_below() -> bool:
	return movement.has_platform_below()

func will_fall_off_edge(direction: float) -> bool:
	return movement.will_fall_off_edge(direction)

func drop_through_platform() -> void:
	movement.drop_through_platform()

func get_walkable_position(pos: Vector2) -> Vector2:
	# Delegate to interaction component
	return interaction.get_walkable_position(pos)

# Removed set_target_position_for_enemy (logic now in ApproachingEnemyState)

# --- Intent Handlers ---

func _on_intent_move_to(position: Vector2):
	print("PLAYER: Intent move to ", position)
	# Clear other targets
	combat.target_enemy = null
	interaction.target_npc = null # Assuming interaction still holds this temporarily
	# Show the indicator at the move position
	if position != Vector2.ZERO:
		_update_target_indicator(position)
		interaction.target_position = position 
		set_state("moving")
	else:
		print("WARN: Invalid move position received.")
		if target_indicator: target_indicator.visible = false # Hide if position is invalid
		interaction.target_position = Vector2.ZERO # Ensure target is cleared
		set_state("idle") 

func _on_intent_attack(enemy: CharacterBody2D):
	print("PLAYER: Intent attack ", enemy.name)
	if not is_instance_valid(enemy) or enemy.get_is_dead(): 
		print("WARN: Invalid enemy target received.")
		set_state("idle") # Go idle if target is invalid
		return

	# Clear NPC target
	interaction.target_npc = null
	# Set combat target
	combat.target_enemy = enemy 
	# EventBus.publish_target_acquired(enemy) # Maybe use this instead of direct setting?
	_update_target_indicator(enemy.global_position - Vector2(0, enemy.indicator_offset))

	# Don't set target_position here, let the Approaching state handle it
	set_state("approaching_enemy")

func _on_intent_interact(npc: CharacterBody2D):
	print("PLAYER: Intent interact ", npc.name)
	if not is_instance_valid(npc):
		print("WARN: Invalid NPC target received.")
		set_state("idle") # Go idle if target is invalid
		return
		
	# Clear combat target
	combat.target_enemy = null
	# Set interaction target (Player holds this now?)
	interaction.target_npc = npc # Let interaction hold it for now
	_update_target_indicator(npc.global_position - Vector2(0, npc.indicator_offset))
	
	# Don't set target_position here, let the Approaching state handle it
	set_state("approaching_npc")

# --- Helper Methods ---

# Method for states to request transitions
func request_state_change(new_state_name: String) -> void:
	# Can add validation here if needed based on current state
	# e.g., if current_state.can_transition_to(new_state_name):
	set_state(new_state_name)

# Moved from PlayerInteraction - ensure target_indicator is the correct node reference
func _update_target_indicator(pos: Vector2) -> void:
	if target_indicator:
		target_indicator.global_position = pos
		target_indicator.visible = true

# Handle Equipment Updates
func _on_equipment_updated(slot_type: String, item: ItemData) -> void:
	match slot_type:
		"weapon":
			if weapon_sprite: # Ensure the node exists
				if item: # An item was equipped
					weapon_sprite.texture = item.icon
					weapon_sprite.visible = true
				else: # The slot was emptied (item unequipped)
					weapon_sprite.texture = null
					weapon_sprite.visible = false
		"head":
			if hat_sprite: # Ensure the node exists
				if item: # An item was equipped
					hat_sprite.texture = item.icon
					hat_sprite.visible = true
				else: # The slot was emptied (item unequipped)
					hat_sprite.texture = null
					hat_sprite.visible = false
		# Add cases for other slots like "chest" if needed
