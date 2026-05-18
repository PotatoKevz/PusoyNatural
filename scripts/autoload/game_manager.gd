extends Node

# Global game state and configuration

const SAVE_FILE = "user://pusoy_save.save"

var current_money: int = 10000
var current_gems: int = 100
var player_name: String = "Player 1"
var total_wins: int = 0
var total_losses: int = 0
var sound_enabled: bool = true
var music_enabled: bool = true

enum TableTier { 
	TONDO, 
	CALOOCAN, 
	QUEZON_CITY, 
	PASAY, 
	CEBU_STREETS, 
	DAVAO_CLUB, 
	PAMPANGA_LOUNGE,
	BORACAY_RESORT,
	TAGUIG_METRO,
	MAKATI_CENTRAL,
	BGC_HIGH_STREET,
	SOLAIRE_VIP,
	OKADA_ROYAL,
	CITY_OF_DREAMS,
	PENTHOUSE_CELESTIAL
}

var current_table_tier: TableTier = TableTier.TONDO

const TIER_SETTINGS = {
	TableTier.TONDO: {"name": "Tondo Street Side", "bet": 10, "min_money": 0, "luxury": 0.0},
	TableTier.CALOOCAN: {"name": "Caloocan Pool Hall", "bet": 50, "min_money": 500, "luxury": 0.1},
	TableTier.QUEZON_CITY: {"name": "QC Karaoke Bar", "bet": 100, "min_money": 2000, "luxury": 0.2},
	TableTier.PASAY: {"name": "Pasay Underground", "bet": 250, "min_money": 5000, "luxury": 0.3},
	TableTier.CEBU_STREETS: {"name": "Cebu Night Market", "bet": 500, "min_money": 10000, "luxury": 0.4},
	TableTier.DAVAO_CLUB: {"name": "Davao Card Club", "bet": 1000, "min_money": 25000, "luxury": 0.5},
	TableTier.PAMPANGA_LOUNGE: {"name": "Clark Jazz Lounge", "bet": 2500, "min_money": 50000, "luxury": 0.6},
	TableTier.BORACAY_RESORT: {"name": "Boracay White Sands", "bet": 5000, "min_money": 100000, "luxury": 0.7},
	TableTier.TAGUIG_METRO: {"name": "Taguig Skyline", "bet": 10000, "min_money": 250000, "luxury": 0.75},
	TableTier.MAKATI_CENTRAL: {"name": "Makati Diamond Club", "bet": 25000, "min_money": 500000, "luxury": 0.8},
	TableTier.BGC_HIGH_STREET: {"name": "BGC High Street VIP", "bet": 50000, "min_money": 1000000, "luxury": 0.85},
	TableTier.SOLAIRE_VIP: {"name": "Solaire Gold Room", "bet": 100000, "min_money": 2500000, "luxury": 0.9},
	TableTier.OKADA_ROYAL: {"name": "Okada Pearl Wing", "bet": 250000, "min_money": 5000000, "luxury": 0.95},
	TableTier.CITY_OF_DREAMS: {"name": "City of Dreams VIP", "bet": 500000, "min_money": 10000000, "luxury": 0.98},
	TableTier.PENTHOUSE_CELESTIAL: {"name": "Celestial Penthouse", "bet": 1000000, "min_money": 25000000, "luxury": 1.0}
}

var current_bet: int = 100
var session_rounds: int = 8 # Default to 8
var current_round: int = 1

func set_tier(tier: TableTier):
	current_table_tier = tier
	current_bet = TIER_SETTINGS[tier]["bet"]
	save_game()

var ai_difficulty: int = 1 # 0: Easy, 1: Normal, 2: Aggressive

signal money_changed(new_amount)
signal gems_changed(new_amount)
signal game_saved

func _ready():
	load_game()

func add_money(amount: int):
	current_money += amount
	money_changed.emit(current_money)
	save_game()

func add_gems(amount: int):
	current_gems += amount
	gems_changed.emit(current_gems)
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
