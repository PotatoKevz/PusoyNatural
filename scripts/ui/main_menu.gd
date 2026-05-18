extends Control

@onready var money_label = $MoneyLabel
@onready var wins_label = $VBoxContainer/StatsPanel/StatsBox/WinsLabel
@onready var losses_label = $VBoxContainer/StatsPanel/StatsBox/LossesLabel

func _ready():
	_update_money_label(GameManager.current_money)
	_update_stats()
	GameManager.money_changed.connect(_update_money_label)

func _update_money_label(amount: int):
	money_label.text = "$ " + _format_money(amount)

func _update_stats():
	wins_label.text = "Wins: " + str(GameManager.total_wins)
	losses_label.text = "Losses: " + str(GameManager.total_losses)

func _format_money(amount: int) -> String:
	var s = str(amount)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result

func _on_play_offline_btn_pressed():
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")

func _on_host_lan_btn_pressed():
	if NetworkManager.host_game():
		print("Hosting game on port ", NetworkManager.PORT)

func _on_join_lan_btn_pressed():
	# Prompt for IP in a real app, assuming localhost for testing
	if NetworkManager.join_game("127.0.0.1"):
		print("Attempting to join LAN game...")
