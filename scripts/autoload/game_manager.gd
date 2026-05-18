extends Node

# Global game state and configuration

const SAVE_FILE = "user://pusoy_save.save"

var current_money: int = 10000
var total_wins: int = 0
var total_losses: int = 0
var sound_enabled: bool = true
var music_enabled: bool = true

enum TableTier { LOW, MEDIUM, HIGH }
var current_table_tier: TableTier = TableTier.LOW

var current_bet: int = 100
var ai_difficulty: int = 1 # 0: Easy, 1: Normal, 2: Aggressive

signal money_changed(new_amount)
signal game_saved

func _ready():
	load_game()

func add_money(amount: int):
	current_money += amount
	money_changed.emit(current_money)
	save_game()

func deduct_money(amount: int) -> bool:
	if current_money >= amount:
		current_money -= amount
		money_changed.emit(current_money)
		save_game()
		return true
	return false

func check_bankruptcy():
	if current_money <= 0:
		# Bonus money system
		current_money = 5000
		money_changed.emit(current_money)
		save_game()
		print("Bankrupt! Given 5000 recovery bonus.")

func record_win():
	total_wins += 1
	save_game()

func record_loss():
	total_losses += 1
	save_game()

func save_game():
	SaveManager.save_data()

func load_game():
	SaveManager.load_data()
