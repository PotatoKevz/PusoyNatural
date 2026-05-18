extends Control

@onready var money_label = $MoneyLabel

func _ready():
	_update_money_label(GameManager.current_money)
	GameManager.money_changed.connect(_update_money_label)

func _update_money_label(amount: int):
	money_label.text = "Money: " + str(amount)

func _on_play_offline_btn_pressed():
	print("Starting Offline Game...")
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")

func _on_host_lan_btn_pressed():
	if NetworkManager.host_game():
		print("Hosting game on port ", NetworkManager.PORT)
		# get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_join_lan_btn_pressed():
	# Prompt for IP in a real app, assuming localhost for testing
	if NetworkManager.join_game("127.0.0.1"):
		print("Attempting to join LAN game...")
