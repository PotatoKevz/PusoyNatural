extends Control

@onready var hand_container = $HandArea/Cards
@onready var head_row = $HeadRow
@onready var body_row = $BodyRow
@onready var base_row = $BaseRow
@onready var money_label = $TopUI/MoneyLabel
@onready var bet_label = $TopUI/BetLabel
@onready var status_label = $TopUI/StatusLabel
@onready var head_label = $HeadLabel
@onready var body_label = $BodyLabel
@onready var base_label = $BaseLabel
@onready var tier_overlay = $TierOverlay
@onready var neon_top = $NeonBorderTop
@onready var neon_bottom = $NeonBorderBottom
@onready var glow_particles = $GlowParticles

var card_ui_scene = preload("res://scenes/card_ui.tscn")
var gameplay_manager: GameplayManager
var _glow_tween: Tween = null
var _neon_tween: Tween = null
var _status_timer: SceneTreeTimer = null

func _ready():
	gameplay_manager = GameplayManager.new()
	add_child(gameplay_manager)

	gameplay_manager.cards_dealt.connect(_on_cards_dealt)
	gameplay_manager.round_ended.connect(_on_round_ended)

	_apply_tier_visuals()
	_update_ui()

	_setup_players()
	gameplay_manager.start_game()

# ── Tier Visual System ────────────────────────────────────────────────────────

func _apply_tier_visuals():
	if _glow_tween:
		_glow_tween.kill()
		_glow_tween = null
	if _neon_tween:
		_neon_tween.kill()
		_neon_tween = null

	match GameManager.current_table_tier:
		GameManager.TableTier.LOW:
			_apply_low_tier()
		GameManager.TableTier.MEDIUM:
			_apply_medium_tier()
		GameManager.TableTier.HIGH:
			_apply_high_tier()

func _apply_low_tier():
	# Casual green casino — simple, no effects
	$Table/Felt.color = Color(0.06, 0.19, 0.06, 0.35)
	$TopUI/ColorRect.color = Color(0, 0, 0, 0.55)
	tier_overlay.color = Color(0, 0, 0, 0)
	neon_top.color = Color(0, 0, 0, 0)
	neon_bottom.color = Color(0, 0, 0, 0)
	glow_particles.emitting = false
	_set_row_label_color(Color(1, 0.843, 0, 1))
	_set_row_panel_border(Color(0.6, 0.5, 0.1, 0.4))
	_reset_button_styles()

func _apply_medium_tier():
	# Metallic blue — better lighting, animated table glow, silver accents
	$Table/Felt.color = Color(0.06, 0.10, 0.34, 0.5)
	$TopUI/ColorRect.color = Color(0.02, 0.04, 0.14, 0.68)
	tier_overlay.color = Color(0.0, 0.02, 0.08, 0.1)
	neon_top.color = Color(0.2, 0.5, 0.9, 0.28)
	neon_bottom.color = Color(0.2, 0.5, 0.9, 0.28)
	glow_particles.emitting = false
	_set_row_label_color(Color(0.7, 0.87, 1.0, 1))
	_set_row_panel_border(Color(0.35, 0.58, 0.92, 0.55))
	_set_medium_button_styles()
	# Animate table felt: subtle blue pulse
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property($Table/Felt, "color", Color(0.08, 0.15, 0.46, 0.68), 1.8)
	_glow_tween.tween_property($Table/Felt, "color", Color(0.06, 0.10, 0.34, 0.5), 1.8)

func _apply_high_tier():
	# Gold/black luxury VIP — dramatic atmosphere, neon edges, particles, gold everything
	$Table/Felt.color = Color(0.14, 0.07, 0.0, 0.72)
	$TopUI/ColorRect.color = Color(0.07, 0.03, 0.0, 0.8)
	tier_overlay.color = Color(0.07, 0.03, 0.0, 0.18)
	neon_top.color = Color(1, 0.75, 0, 0.5)
	neon_bottom.color = Color(1, 0.75, 0, 0.5)
	glow_particles.emitting = true
	_set_row_label_color(Color(1, 0.9, 0.3, 1))
	_set_row_panel_border(Color(1.0, 0.78, 0.0, 0.7))
	_set_high_button_styles()
	# Animate table felt: warm gold pulse
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property($Table/Felt, "color", Color(0.22, 0.11, 0.0, 0.85), 1.3)
	_glow_tween.tween_property($Table/Felt, "color", Color(0.12, 0.06, 0.0, 0.6), 1.3)
	# Animate neon borders: pulsing gold glow
	_neon_tween = create_tween().set_loops()
	_neon_tween.tween_property(neon_top, "color", Color(1, 0.84, 0, 0.85), 0.7)
	_neon_tween.parallel().tween_property(neon_bottom, "color", Color(1, 0.84, 0, 0.85), 0.7)
	_neon_tween.tween_property(neon_top, "color", Color(1, 0.65, 0, 0.25), 0.7)
	_neon_tween.parallel().tween_property(neon_bottom, "color", Color(1, 0.65, 0, 0.25), 0.7)

# ── Tier Helpers ──────────────────────────────────────────────────────────────

func _set_row_label_color(color: Color):
	head_label.add_theme_color_override("font_color", color)
	body_label.add_theme_color_override("font_color", color)
	base_label.add_theme_color_override("font_color", color)

func _set_row_panel_border(color: Color):
	# All 3 row panels share the same StyleBoxFlat resource — change once affects all
	var style = $HeadBg.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.border_color = color

func _reset_button_styles():
	$Controls/SortBtn.remove_theme_stylebox_override("normal")
	$Controls/SortBtn.remove_theme_color_override("font_color")
	$Controls/ResetBtn.remove_theme_stylebox_override("normal")
	$Controls/ResetBtn.remove_theme_color_override("font_color")
	$Controls/SubmitBtn.remove_theme_stylebox_override("normal")
	$Controls/SubmitBtn.remove_theme_color_override("font_color")

func _set_medium_button_styles():
	# Metallic silver-blue accents
	var sort_style = _make_button_style(Color(0.06, 0.12, 0.30, 1), Color(0.55, 0.75, 1.0, 1))
	$Controls/SortBtn.add_theme_stylebox_override("normal", sort_style)
	$Controls/SortBtn.add_theme_color_override("font_color", Color(0.8, 0.92, 1.0, 1))

	var reset_style = _make_button_style(Color(0.30, 0.15, 0.02, 1), Color(1.0, 0.78, 0.4, 1))
	$Controls/ResetBtn.add_theme_stylebox_override("normal", reset_style)
	$Controls/ResetBtn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75, 1))

	var submit_style = _make_button_style(Color(0.04, 0.24, 0.08, 1), Color(0.45, 0.95, 0.55, 1))
	$Controls/SubmitBtn.add_theme_stylebox_override("normal", submit_style)
	$Controls/SubmitBtn.add_theme_color_override("font_color", Color(0.85, 1.0, 0.88, 1))

func _set_high_button_styles():
	# All-gold luxury VIP — dark charcoal bg, gold borders, gold text, gold shadow
	for btn_name in ["SortBtn", "ResetBtn", "SubmitBtn"]:
		var btn = $Controls.get_node(btn_name) as Button
		var style = _make_button_style(Color(0.10, 0.07, 0.02, 1), Color(1, 0.84, 0, 1))
		style.shadow_color = Color(1, 0.7, 0, 0.4)
		style.shadow_size = 8
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_color_override("font_color", Color(1, 0.92, 0.5, 1))

func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.border_color = border
	s.corner_radius_top_left = 14
	s.corner_radius_top_right = 14
	s.corner_radius_bottom_right = 14
	s.corner_radius_bottom_left = 14
	return s

# ── Game Setup ────────────────────────────────────────────────────────────────

func _setup_players():
	var human = PlayerBase.new()
	human.id = 0
	gameplay_manager.players.append(human)

	for i in range(1, 4):
		var ai = AIPlayer.new(i, GameManager.ai_difficulty)
		gameplay_manager.players.append(ai)

func _on_cards_dealt():
	var human = gameplay_manager.players[0]
	for card in human.cards:
		var card_ui = card_ui_scene.instantiate()
		hand_container.add_child(card_ui)
		card_ui.setup(card)
		card_ui.gui_input.connect(_on_card_gui_input.bind(card_ui))
	_update_row_labels()

# ── UI Updates ────────────────────────────────────────────────────────────────

func _update_ui():
	money_label.text = "$ " + _format_money(GameManager.current_money)
	bet_label.text = "Bet: $" + str(GameManager.current_bet)

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

func _update_row_labels():
	head_label.text = "HEAD  (%d/3)" % head_row.get_child_count()
	body_label.text = "BODY  (%d/5)" % body_row.get_child_count()
	base_label.text = "BASE  (%d/5)" % base_row.get_child_count()

func _show_status(msg: String, color: Color = Color(1, 0.4, 0.4, 1)):
	status_label.text = msg
	status_label.add_theme_color_override("font_color", color)
	if _status_timer != null:
		_status_timer = null
	_status_timer = get_tree().create_timer(2.5)
	_status_timer.timeout.connect(func(): status_label.text = "")

# ── Card Interaction ──────────────────────────────────────────────────────────

func _on_card_gui_input(event, card_ui):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_move_card(card_ui)

func _move_card(card_ui):
	var current_parent = card_ui.get_parent()

	if current_parent == hand_container:
		if head_row.get_child_count() < 3:
			_reparent_card(card_ui, head_row)
		elif body_row.get_child_count() < 5:
			_reparent_card(card_ui, body_row)
		elif base_row.get_child_count() < 5:
			_reparent_card(card_ui, base_row)
	else:
		_reparent_card(card_ui, hand_container)
	_update_row_labels()

func _reparent_card(card_ui, new_parent):
	card_ui.get_parent().remove_child(card_ui)
	new_parent.add_child(card_ui)

func _on_sort_btn_pressed():
	var cards = []
	for child in hand_container.get_children():
		cards.append(child)
	cards.sort_custom(func(a, b): return a.card_data.compare(b.card_data) > 0)
	for child in cards:
		hand_container.move_child(child, -1)

func _on_reset_btn_pressed():
	for row in [head_row, body_row, base_row]:
		for child in row.get_children():
			_reparent_card(child, hand_container)
	_update_row_labels()
	_show_status("Cards reset.", Color(0.8, 0.8, 0.8, 1))

func _on_submit_btn_pressed():
	if head_row.get_child_count() != 3 or body_row.get_child_count() != 5 or base_row.get_child_count() != 5:
		_show_status("Place all 13 cards first!", Color(1, 0.4, 0.4, 1))
		return

	var head = _get_cards_from_row(head_row)
	var body = _get_cards_from_row(body_row)
	var base = _get_cards_from_row(base_row)

	if gameplay_manager.submit_hand(0, head, body, base):
		_show_status("Hand submitted!", Color(0.4, 1, 0.5, 1))
	else:
		_show_status("Invalid! HEAD < BODY < BASE", Color(1, 0.4, 0.4, 1))

func _get_cards_from_row(row):
	var cards: Array[Card] = []
	for child in row.get_children():
		cards.append(child.card_data)
	return cards

# ── Round End ─────────────────────────────────────────────────────────────────

var pusoy_effect_scene = preload("res://scenes/effects/pusoy_effect.tscn")

func _on_round_ended(results):
	_update_ui()
	if results.human_score >= 6:
		_trigger_pusoy_effect()
		_show_status("PUSOY! Perfect sweep!", Color(1, 0.843, 0, 1))
	elif results.human_score > 0:
		_show_status("You won %d hands!" % results.human_score, Color(0.4, 1, 0.5, 1))
	else:
		_show_status("Better luck next round.", Color(0.8, 0.8, 0.8, 1))

func _trigger_pusoy_effect():
	var effect = pusoy_effect_scene.instantiate()
	add_child(effect)
	_shake_screen(0.5, 20)

func _shake_screen(duration: float, intensity: float):
	var tween = create_tween()
	var original_pos = position
	for i in range(10):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(self, "position", original_pos + offset, duration / 10.0)
	tween.tween_property(self, "position", original_pos, duration / 10.0)
