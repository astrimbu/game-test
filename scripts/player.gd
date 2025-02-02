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

# Forward some commonly accessed properties to keep state code cleaner
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_shooting: bool:
	get: return combat.is_shooting
	set(value): combat.is_shooting = value
var target_enemy: CharacterBody2D:
	get: return combat.target_enemy
	set(value): combat.set_target(value)
var target_position: Vector2:
	get: return interaction.target_position
	set(value): interaction.set_movement_target(value)
var target_npc: CharacterBody2D:
	get: return interaction.target_npc
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
	interaction.target_indicator = target_indicator
	
	# Initialize states
	states = {
		"idle": IdleState.new(),
		"walking": WalkingState.new(),
		"jumping": JumpingState.new(),
		"moving_to_target": MovingToTargetState.new(),
		"shooting": ShootingState.new()
	}
	
	# Connect component signals
	_connect_component_signals()
	
	# Start in idle state
	set_state("idle")

func _connect_component_signals() -> void:
	# Movement signals
	movement.jumped.connect(func(): animation_player.play("jump"))
	movement.started_moving.connect(func(): animation_player.play("walk"))
	movement.stopped_moving.connect(func(): 
		if not is_shooting:
			animation_player.play("idle")
	)
	
	# Combat signals - use EventBus now
	EventBus.combat_animation_started.connect(func(anim_name: String): animation_player.play(anim_name))
	EventBus.combat_animation_ended.connect(func(anim_name: String): animation_player.play("idle"))
	EventBus.enemy_killed.connect(func(enemy): 
		interaction.clear_targets()
		set_state("idle")
	)
	
	# Interaction signals
	interaction.target_reached.connect(func(target):
		if target is CharacterBody2D and target.has_method("start_interaction"):
			target.start_interaction()
	)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.update_state(self, delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(self, event)

func set_state(new_state_name: String) -> void:
	if current_state:
		current_state.exit_state(self)
	
	current_state = states[new_state_name]
	current_state.enter_state(self)

# Delegate methods to components
func shoot(is_auto: bool = false) -> void:
	combat.shoot(is_auto)

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
	return interaction.get_walkable_position(pos)
