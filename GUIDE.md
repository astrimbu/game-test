# Project Structure Guide

This guide outlines the locations of various game mechanics and systems within the codebase.

## Scripts (`scripts/`)

This directory contains the core game logic.

*   **Player:** Handles player character logic, resources, and states.
    *   `player.gd`: Main player script.
    *   `player_resources.gd`: Manages player-specific resources (e.g., health, mana).
    *   `player_states/`: Contains different states for the player character (e.g., Idle, Walking, Attacking).
        *   `player_state.gd`: Base class for all player states.
        *   `idle_state.gd`
        *   `moving_state.gd`
        *   `manual_moving_state.gd`
        *   `walking_state.gd`
        *   `jumping_state.gd`
        *   `attacking_state.gd`
        *   `shooting_state.gd`
        *   `approaching_enemy_state.gd`
        *   `approaching_npc_state.gd`
*   **State Machine:**
    *   `state_machine.gd`: A general-purpose state machine implementation, likely used by various entities. *(Note: This appears to be an older implementation where states are child nodes. The player (`player.gd`) uses a different approach with state objects managed in a dictionary. This script might be unused or used by NPCs/enemies.)*
*   **Interaction:**
    *   `interaction_system.gd`: Manages interactions between the player and world objects.
*   **Items:**
    *   `dropped_item.gd`: Logic for items dropped in the world. (Item definitions might be in `resources/`).
*   **UI:** Contains user interface elements and logic.
    *   `ui/`: Directory for UI scenes and scripts.
        *   `ui.gd`: Main controller for the game's UI.
        *   `inventory_ui.gd`: Script for the inventory panel.
        *   `equipment_ui.gd`: Script for the equipment panel.
        *   `pause_ui.gd`: Script for the pause menu.
        *   `inventory_slot_ui.gd`: Logic for an individual inventory slot UI element.
        *   `equipment_slot_ui.gd`: Logic for an individual equipment slot UI element.
        *   `resources_ui.gd`: Displays player resources (like health, mana).
*   **Components:** Reusable components attached to game objects. Mostly player-focused.
    *   `components/`: Directory for component scripts.
        *   `player_interaction.gd`: Handles player's ability to interact with the world. Interprets mouse clicks: checks for items first (pickup on mouse down), then NPCs/enemies (on mouse up). Emits intent signals (`intent_move_to`, `intent_attack`, `intent_interact`) based on what was clicked (or ground position). Finds walkable positions using raycasts, updates the target indicator, and manages interaction target state.
        *   `player_combat.gd`: Manages player combat logic. Determines attack properties (style, range, cooldown, animation, damage delay) based on equipped weapon or unarmed defaults. Uses Timers to manage the attack sequence (animation start, damage application delay, cooldown, animation end). Applies damage to target enemy, handles attack looping (auto-combat), listens for enemy death via EventBus, and calculates total damage.
        *   `player_movement.gd`: Controls player movement.
        *   `player_animation.gd`: Drives player animations.
*   **Autoload/Singletons:** Globally accessible scripts/managers.
    *   `autoload/`: Directory for autoloaded scripts.
        *   `inventory_manager.gd`: Manages the player's inventory and equipment. Connects to the EventBus for item pickups, modifies data in `GameState.player_data`, provides functions for equipping/unequipping/adding/moving items, and emits signals (`inventory_updated`, `equipment_updated`) to notify UI.
        *   `save_manager.gd`: Handles saving and loading game state to/from `user://game_save.dat`. Uses `FileAccess.store_var`/`get_var`. Relies on the global `GameState` singleton for the data to save (`GameState.to_dict()`) and applies loaded data back to it (`GameState.from_dict()`). Includes some older methods for updating specific parts of the state locally.
        *   `game_state.gd`: Tracks the overall game state (e.g., paused, running).
        *   `event_bus.gd`: A global event system (Singleton/Autoload) for decoupled communication. Defines many signals for various game events (combat, items, resources, quests, state changes, etc.). Provides `publish_*` helper functions that emit signals and sometimes perform related actions (like updating `GameState` or saving the game). Includes a debug reset function.
*   **Enemies:** Logic related to enemy characters.
    *   `enemies/`: Directory for enemy-specific scripts and potentially states.
        *   `base_enemy.gd`: Base class for all enemies. Handles core logic like health, taking damage, dying (plays a "death" animation if available, disables collision/physics, then hides sprite), dropping items, and requesting respawns. Includes a `respawn()` method to reset state, re-enable collision/physics, show the sprite, and reposition the enemy.
        *   `enemy_movement_controller.gd`: Handles movement logic for enemies.
        *   `squiddy_enemy.gd`: Specific logic for the Squiddy enemy type.
        *   `bat_enemy.gd`: Specific logic for the Bat enemy type. Defines paths to nodes (Sprite, AnimationPlayer) used by BaseEnemy.
*   **World:** General world logic.
    *   `world.gd`: Script for the main game world scene.
*   **Quests:** Systems for managing quests.
    *   `quest.gd`: Base quest script.
    *   `quest_data.gd`: Data structure for quest information.
    *   `quest_database.gd`: Holds all available quests.
    *   `quest_manager.gd`: Tracks active quests and player progress.
*   **Skilling:** Handles player skills and progression.
    *   `skilling/`: Directory for skilling-related logic. *(Currently empty)*
*   **NPCs:** Non-player character logic.
    *   `npcs/`: Directory for NPC scripts and potentially states/dialogue.
        *   `base_npc.gd`: Base class for NPCs.
        *   `squiddy_npc.gd`: Specific logic for the Squiddy NPC.
        *   `shopkeeper_npc.gd`: Specific logic for the Shopkeeper NPC.
*   **Resources:** Contains custom Resource script definitions (`.gd`) and pre-configured Resource instances (`.tres`).
    *   `resources/`: Directory for Resource scripts and files.
        *   *Examples:* `item_data.gd`, `player_config.gd`, `wooden_sword.tres`, `health_potion.tres`

### `ItemData` Resource (`scripts/resources/item_data.gd`)

This resource defines the properties of an item.

- **`id`**: Unique string identifier (e.g., "simple_sword").
- **`unique_id`**: Automatically generated unique ID for instance tracking.
- **`name`**: Display name (e.g., "Simple Sword").
- **`description`**: Flavor text or details.
- **`type`**: Enum (`CONSUMABLE`, `EQUIPMENT`, `RESOURCE`).
- **`rarity`**: Enum (`COMMON`, `UNCOMMON`, `RARE`, `EPIC`).
- **`icon`**: `Texture2D` for UI display.
- **`stackable`**: Boolean, can multiple instances stack in one slot?
- **`max_stack`**: Integer, maximum stack size if stackable.

#### Display Adjustments

These properties control how the item looks when dropped or in UI slots:

- **`dropped_scale`**: `Vector2` scale applied to the sprite when the item is dropped in the world. Default `(1, 1)`.
- **`dropped_offset`**: `Vector2` positional offset applied when the item is dropped in the world. Added to the target ground position. Default `(0, 0)`.
- **`ui_icon_offset`**: `Vector2` positional offset applied to the item's icon within UI slots (Inventory and Equipment). Useful for centering or adjusting specific sprites. Default `(0, 0)`.

#### Equipment Properties

- **`equip_slot`**: String indicating the target slot (e.g., "head", "weapon").
- **`stats`**: Dictionary for stats provided when equipped (e.g., `{"damage": 5}`).

#### Consumable Properties

- **`use_effect`**: Dictionary describing the effect when used (e.g., `{"heal": 20}`).

---

*This guide is automatically generated and may need further refinement.*

# Player

## Player Movement

The player character is controlled using a state machine pattern located in `scripts/player_states/`. Movement logic is primarily handled by the `PlayerMovement` component (`scripts/components/player_movement.gd`). Horizontal movement is now instantaneous, without acceleration or friction.

### Keyboard Movement

Keyboard input (`ui_left`, `ui_right`) is handled in the `ManualMovingState`. It transitions from `IdleState` when movement keys are pressed and back when they are released.

### Mouse Click Movement

Mouse clicks are handled by the `PlayerInteraction` component (`scripts/components/player_interaction.gd`). It determines the clicked object or position and emits intent signals:

*   `intent_move_to`: If ground is clicked, the player enters the `MovingState` to move towards the `target_position`.
*   `intent_attack`: If an enemy is clicked, the player enters `ApproachingEnemyState`.
*   `intent_interact`: If an NPC is clicked, the player enters `ApproachingNPCState`.

The `MovingState` handles pathfinding to the `target_position` set by the interaction component.

### Jumping and Falling

Jumping (`ui_up`) is handled in the `JumpingState`. Gravity is applied in each state's `apply_gravity` helper function.

### Edge Detection

The player character now checks for ground slightly ahead before moving horizontally (both via keyboard input and mouse clicks) when on the floor. If no ground is detected (i.e., moving towards an edge), horizontal movement is prevented, stopping the player at the platform edge. This logic resides in the `PlayerMovement.will_fall_off_edge` method, which uses the `CharacterBody2D.test_move` function to predict collisions, and is checked within the `ManualMovingState` and `MovingState` update functions.

## Player Combat

The player combat logic is managed by the `PlayerCombat` component (`scripts/components/player_combat.gd`). It determines attack properties (style, range, cooldown, animation, damage delay) based on equipped weapon or unarmed defaults. Uses Timers to manage the attack sequence (animation start, damage application delay, cooldown, animation end). Applies damage to target enemy, handles attack looping (auto-combat), listens for enemy death via EventBus, and calculates total damage.

### Item Pickup

- **Dropped Items:** Items dropped by enemies (coins, equipment) appear on the ground.
- **Pickup:** Click and hold the left mouse button and drag the cursor over items on the ground to pick them up. Items within range will be collected automatically.
- **Inventory:** Collected items (except coins) are added to the player's inventory.

---

## Debugging

Debug prints are used throughout the codebase for development and testing. To reduce console spam, some frequently called functions (like `PlayerMovement.set_facing_direction`) now only print debug messages when a relevant state change occurs (e.g., when the player actually changes direction). Additionally, verbose prints related to velocity changes during movement (`PlayerMovement.move`) and raycasting for walkable positions (`PlayerInteraction.get_walkable_position`) have been commented out by default, but can be re-enabled if needed for specific debugging tasks.

## Enemy Drops

Enemy drop logic is handled within `scripts/enemies/base_enemy.gd` in the `spawn_dropped_items()` and `get_random_drop()` functions.

*   **Coins:** All enemies drop their specified `coin_value`.
*   **Items:**
    *   Currently, only the `bat_enemy` has a chance to drop items defined in its `get_random_drop` override within `base_enemy.gd`.
    *   `bat_enemy` has a 1/3 (33%) chance to drop `hat1` (Simple Hat).
    *   `bat_enemy` has a 1/3 (33%) chance to drop a `wooden_sword`. *(Note: The probabilities are checked sequentially).*
    *   All enemies now play a "death" animation (if one exists with that name in their `AnimationPlayer`) when defeated, after which their sprite is hidden (managed by `base_enemy.gd`).
    *   Both `hat1` and `wooden_sword` are defined as `ItemData` resources (`.tres` files) in `scripts/resources/` and can be picked up and equipped by the player.
    *   Other enemies currently do not drop any items.

*   **Quests:** Systems for managing quests.
    *   `quest.gd`: Base quest script.
    *   `quest_data.gd`: Data structure for quest information.
    *   `quest_database.gd`: Holds all available quests.
    *   `quest_manager.gd`: Tracks active quests and player progress. 