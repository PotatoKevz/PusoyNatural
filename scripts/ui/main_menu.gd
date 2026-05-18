extends Control

@onready var chips_label = $TopBar/HBox/ChipsBox/HBox/ChipsLabel
@onready var gems_label = $TopBar/HBox/GemsBox/HBox/GemsLabel
@onready var player_name_label = $TopBar/HBox/AvatarBox/PlayerName

func _ready():
	_update_money_label(GameManager.current_money)
	_update_gems_label(GameManager.current_gems)
	player_name_label.text = GameManager.player_name
	
	GameManager.money_changed.connect(_update_money_label)
	GameManager.gems_changed.connect(_update_gems_label)

func _update_money_label(amount: int):
	chips_label.text = _format_money(amount)

func _update_gems_label(amount: int):
	gems_label.text = _format_money(amount)

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

# ── Main Actions ──────────────────────────────────────────────────────────────

func _on_play_offline_btn_pressed():
	_show_tier_selection()

func _on_leaderboard_pressed():
	_show_simple_popup("LEADERBOARD", "Top Players:\n1. DragonKing - $5M\n2. PusoyPro - $2.1M\n3. %s - %s" % [GameManager.player_name, _format_money(GameManager.current_money)])

func _on_multiplayer_pressed():
	_show_simple_popup("MULTIPLAYER", "Online matchmaker currently in maintenance.\nTry LAN hosting in Settings.")

# ── Bottom Nav Actions ────────────────────────────────────────────────────────

func _on_profile_pressed():
	_show_simple_popup("PROFILE", "Name: %s\nWins: %d\nLosses: %d" % [GameManager.player_name, GameManager.total_wins, GameManager.total_losses])

func _on_tasks_pressed():
	_show_simple_popup("TASKS", "Daily Tasks:\n- Win 3 rounds: [0/3] (Reward: $1000)\n- Play Macau 1 time: [0/1] (Reward: 5 Gems)")

func _on_settings_pressed():
	# Simple settings toggle logic could go here
	_show_simple_popup("SETTINGS", "Sound: ON\nMusic: ON\nHost LAN: Active\nJoin LAN: Ready")

func _on_shop_pressed():
	_show_simple_popup("SHOP", "Exchange Gems for Chips?\n10 Gems = $1,000\n[Insufficient Gems]")

# ── Helpers ───────────────────────────────────────────────────────────────────

func _show_tier_selection():
	var tier_popup = ColorRect.new()
	tier_popup.name = "TierSelection"
	tier_popup.color = Color(0, 0, 0, 0.85)
	tier_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(tier_popup)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.theme_override_constants_separation = 20
	tier_popup.add_child(vbox)
	
	var title = Label.new()
	title.text = "SELECT LOCATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	vbox.add_child(title)
	
	for tier in GameManager.TableTier.values():
		var settings = GameManager.TIER_SETTINGS[tier]
		var btn = Button.new()
		btn.text = "%s\nBet: $%d | Min: $%d" % [settings["name"], settings["bet"], settings["min_money"]]
		btn.custom_minimum_size = Vector2(400, 100)
		
		if GameManager.current_money < settings["min_money"]:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5, 1)
		
		btn.pressed.connect(func(): _start_game_with_tier(tier))
		vbox.add_child(btn)
	
	var back_btn = Button.new()
	back_btn.text = "BACK"
	back_btn.pressed.connect(func(): tier_popup.queue_free())
	vbox.add_child(back_btn)

func _start_game_with_tier(tier: GameManager.TableTier):
	GameManager.set_tier(tier)
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")

func _show_simple_popup(title_text: String, body_text: String):
	var popup = ColorRect.new()
	popup.color = Color(0, 0, 0, 0.9)
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(popup)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.theme_override_constants_separation = 30
	popup.add_child(vbox)
	
	var t = Label.new()
	t.text = title_text
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 42)
	t.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(t)
	
	var b = Label.new()
	b.text = body_text
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_font_size_override("font_size", 24)
	vbox.add_child(b)
	
	var close_btn = Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(150, 60)
	close_btn.pressed.connect(func(): popup.queue_free())
	vbox.add_child(close_btn)
