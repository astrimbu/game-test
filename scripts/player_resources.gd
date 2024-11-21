class_name PlayerResources
extends Node

signal xp_changed(new_xp: int)
signal coins_changed(new_coins: int)
signal level_up(new_level: int)

var xp: int = 0
var coins: int = 0
var level: int = 1

func add_xp(amount: int) -> void:
    xp += amount
    xp_changed.emit(xp)
    check_level_up()

func add_coins(amount: int) -> void:
    coins += amount
    coins_changed.emit(coins)

func check_level_up() -> void:
    var xp_for_next_level = level * 100  # Simple formula, adjust as needed
    if xp >= xp_for_next_level:
        level += 1
        level_up.emit(level)