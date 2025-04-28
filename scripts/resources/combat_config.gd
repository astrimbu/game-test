extends Resource
class_name CombatConfig

@export var base_damage: int = 1
@export var default_attack_range: float = 100.0
@export var projectile_speed: float = 300.0

# Unarmed Combat Defaults
@export var unarmed_attack_style: String = "unarmed"
@export var unarmed_attack_range: float = 15.0
@export var unarmed_attack_cooldown: float = 0.6
@export var unarmed_attack_animation: String = "punch"
@export var unarmed_damage_delay: float = 0.4 # Time into animation when damage applies
@export var unarmed_animation_duration: float = 1.0 # Total duration of the attack animation
