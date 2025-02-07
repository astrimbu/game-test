extends Node

# Combat signals
signal enemy_hit(enemy: CharacterBody2D)
signal enemy_killed(enemy: CharacterBody2D)

# Item signals
signal item_collected(item_data: Dictionary)  # coins
signal item_picked_up(item: ItemData)  # inventory items
signal item_dropped(item: ItemData)
signal equipment_changed(slot: String, item: ItemData)

# Resource signals
signal xp_gained(amount: int)
signal coins_gained(amount: int)
signal level_up(new_level: int)

# Map signals
signal map_changed(map_id: String)
signal map_unlocked(map_id: String)

# Quest signals
signal quest_started(quest_id: String)
signal quest_updated(quest_id: String, objective: String)
signal quest_completed(quest_id: String)

# Additional combat signals
signal combat_started
signal combat_ended
signal player_hit
signal player_died

# New combat signals
signal weapon_changed(weapon: ItemData)
signal ability_used(ability_name: String)
signal status_effect_applied(target: Node, effect: String, duration: float)
signal status_effect_removed(target: Node, effect: String)
signal combat_state_changed(new_state: String)  # "idle", "combat", "cooldown"
signal damage_dealt(amount: int, target: Node)
signal damage_taken(amount: int, source: Node)

# Combat animation signals
signal combat_animation_started(animation_name: String)
signal combat_animation_ended(animation_name: String)

# Spawn/Respawn signals
signal enemy_spawned(enemy: BaseEnemy, position: Vector2)
signal enemy_respawn_requested(enemy_type: String, position: Vector2)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

# Add these new signals after the existing combat signals
signal auto_combat_started(target: CharacterBody2D)
signal auto_combat_ended
signal target_acquired(target: CharacterBody2D)
signal target_lost

# Dev tool signals
signal game_state_reset
signal toggle_pause

# Helper functions to emit signals and handle side effects
func publish_enemy_hit(enemy: CharacterBody2D) -> void:
	enemy_hit.emit(enemy)

func publish_enemy_killed(enemy: CharacterBody2D) -> void:
	enemy_killed.emit(enemy)
	# Future: Quest system can listen for this

func publish_item_picked_up(item: ItemData) -> void:
	item_picked_up.emit(item)
	SaveManager.save_game()

func publish_equipment_changed(slot: String, item: ItemData) -> void:
	print("EventBus: Equipment changed - Slot:", slot, " Item:", item.name if item else "none")
	equipment_changed.emit(slot, item)
	SaveManager.save_game()

func publish_xp_gained(amount: int) -> void:
	GameState.player_data.xp += amount
	xp_gained.emit(amount)
	SaveManager.save_game()

func publish_coins_gained(amount: int) -> void:
	GameState.player_data.coins += amount
	coins_gained.emit(amount)
	SaveManager.save_game()

func publish_player_hit(damage: int) -> void:
	player_hit.emit(damage)
	# Could trigger screen effects, sound, etc.

func publish_player_died() -> void:
	player_died.emit()
	# Could trigger game over screen, respawn logic, etc.

# New helper functions for combat
func publish_damage_dealt(amount: int, target: Node) -> void:
	damage_dealt.emit(amount, target)
	
	# Check if target exists and is dead
	if target and target.has_method("is_dead") and target.is_dead():
		if target is CharacterBody2D:  # Assuming enemies are CharacterBody2D
			publish_enemy_killed(target)

func publish_damage_taken(amount: int, source: Node) -> void:
	damage_taken.emit(amount, source)
	
	# Update GameState health
	if GameState.player_data.health <= 0:
		publish_player_died()

func publish_status_effect(target: Node, effect: String, duration: float) -> void:
	status_effect_applied.emit(target, effect, duration)
	# Could start a timer to automatically remove the effect
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		status_effect_removed.emit(target, effect)

func publish_ability_used(ability_name: String) -> void:
	ability_used.emit(ability_name)
	# Could trigger cooldown system, animation effects, etc.

func publish_weapon_changed(weapon: ItemData) -> void:
	weapon_changed.emit(weapon)
	# Could update player stats, animations, etc.

func publish_combat_state_change(new_state: String) -> void:
	combat_state_changed.emit(new_state)
	match new_state:
		"combat":
			combat_started.emit()
		"idle":
			combat_ended.emit()

# New spawn/respawn helper functions
func request_enemy_spawn(enemy_type: String, position: Vector2) -> void:
	enemy_respawn_requested.emit(enemy_type, position)

func publish_enemy_spawned(enemy: BaseEnemy, position: Vector2) -> void:
	enemy_spawned.emit(enemy, position)

func publish_wave_started(wave_number: int) -> void:
	wave_started.emit(wave_number)

func publish_wave_completed(wave_number: int) -> void:
	wave_completed.emit(wave_number)

# Add these new helper functions at the bottom
func publish_auto_combat_started(target: CharacterBody2D) -> void:
	auto_combat_started.emit(target)
	combat_started.emit()

func publish_auto_combat_ended() -> void:
	auto_combat_ended.emit()
	combat_ended.emit()

func publish_target_acquired(target: CharacterBody2D) -> void:
	target_acquired.emit(target)

func publish_target_lost() -> void:
	target_lost.emit()

func publish_item_collected(item_data: Dictionary) -> void:
	item_collected.emit(item_data)

func publish_inventory_item_collected(item: ItemData) -> void:
	print("EventBus: Adding item to inventory:", item.name)
	item_picked_up.emit(item)
	SaveManager.save_game()

func reset_game_state() -> void:
	print("EventBus: Resetting game state")
	
	# Create fresh PlayerData
	GameState.player_data = PlayerData.new()
	
	# Delete save file
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists("save.json"):
		dir.remove("save.json")
	
	# Force UI refresh
	if get_tree().root.has_node("UI"):
		var ui = get_tree().root.get_node("UI")
		ui.refresh_ui()
	
	# Emit signals to update all listeners
	coins_gained.emit(0)  # Force ResourcesUI to update
	xp_gained.emit(0)     # Force ResourcesUI to update
	level_up.emit(1)      # Reset level display
	game_state_reset.emit()
	
	print("EventBus: Game state reset complete")

func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("debug_reset"):
		reset_game_state()
