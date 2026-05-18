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

	var tier_data = GameManager.TIER_SETTINGS[GameManager.current_table_tier]
	var luxury = tier_data.get("luxury", 0.0)
	
	# Base Atmosphere: Dim Green (0.0) -> Rich Blue (0.5) -> Royal Gold/Black (1.0)
	var felt_color = Color(0.06, 0.19, 0.06, 0.35) # Default Tondo
	var row_color = Color(1, 0.84, 0, 1) # Default Gold
	
	if luxury < 0.3: # Humble / Slums
		felt_color = Color(0.06, 0.15, 0.06).lerp(Color(0.1, 0.1, 0.1), luxury * 3)
		row_color = Color(0.6, 0.6, 0.5, 1)
		glow_particles.emitting = false
		neon_top.color = Color(0,0,0,0)
		neon_bottom.color = Color(0,0,0,0)
	elif luxury < 0.7: # Professional / City
		felt_color = Color(0.06, 0.1, 0.3).lerp(Color(0.1, 0.05, 0.2), (luxury-0.3) * 2.5)
		row_color = Color(0.7, 0.85, 1.0, 1)
		glow_particles.emitting = false
		neon_top.color = Color(0.2, 0.5, 1.0, 0.2)
		neon_bottom.color = Color(0.2, 0.5, 1.0, 0.2)
	else: # Luxurious / VIP
		felt_color = Color(0.1, 0.05, 0.0).lerp(Color(0.05, 0.02, 0.0), (luxury-0.7) * 3.3)
		row_color = Color(1.0, 0.85, 0.3, 1)
		glow_particles.emitting = true
		neon_top.color = Color(1.0, 0.8, 0, 0.5)
		neon_bottom.color = Color(1.0, 0.8, 0, 0.5)
		
		# Animate VIP Neon
		_neon_tween = create_tween().set_loops()
		_neon_tween.tween_property(neon_top, "color", Color(1, 0.9, 0.2, 0.8), 0.8)
		_neon_tween.parallel().tween_property(neon_bottom, "color", Color(1, 0.9, 0.2, 0.8), 0.8)
		_neon_tween.tween_property(neon_top, "color", Color(1, 0.6, 0, 0.3), 0.8)
		_neon_tween.parallel().tween_property(neon_bottom, "color", Color(1, 0.6, 0, 0.3), 0.8)

	$Table/Felt.color = felt_color
	_set_row_label_color(row_color)
	_apply_button_luxury_styles(luxury)

func _apply_button_luxury_styles(luxury: float):
	_reset_button_styles()
	if luxury > 0.7:
		_set_high_button_styles()
	elif luxury > 0.3:
		_set_medium_button_styles()

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
	var head = _get_cards_from_row(head_row)
	var body = _get_cards_from_row(body_row)
	var base = _get_cards_from_row(base_row)

	var h_eval = HandEvaluator.evaluate(head)
	var m_eval = HandEvaluator.evaluate(body)
	var b_eval = HandEvaluator.evaluate(base)

	var h_name = HandEvaluator.get_rank_name(h_eval.rank) if head.size() == 3 else "(%d/3)" % head.size()
	var m_name = HandEvaluator.get_rank_name(m_eval.rank) if body.size() == 5 else "(%d/5)" % body.size()
	var b_name = HandEvaluator.get_rank_name(b_eval.rank) if base.size() == 5 else "(%d/5)" % base.size()

	head_label.text = "HEAD: " + h_name
	body_label.text = "BODY: " + m_name
	base_label.text = "BASE: " + b_name

	# Validation Highlighting (Mali Check)
	var is_valid = true
	if head.size() == 3 and body.size() == 5:
		if HandEvaluator._compare_evals(m_eval, h_eval) < 0:
			body_label.add_theme_color_override("font_color", Color.RED)
			is_valid = false
		else:
			_apply_tier_label_colors() # Reset to tier default

	if body.size() == 5 and base.size() == 5:
		if HandEvaluator._compare_evals(b_eval, m_eval) < 0:
			base_label.add_theme_color_override("font_color", Color.RED)
			is_valid = false
		else:
			if is_valid: _apply_tier_label_colors()
	
	_update_risk_meter()

func _apply_tier_label_colors():
	match GameManager.current_table_tier:
		GameManager.TableTier.LOW: _set_row_label_color(Color(1, 0.843, 0, 1))
		GameManager.TableTier.MEDIUM: _set_row_label_color(Color(0.7, 0.87, 1.0, 1))
		GameManager.TableTier.HIGH: _set_row_label_color(Color(1, 0.9, 0.3, 1))

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
	var old_pos = card_ui.global_position
	card_ui.get_parent().remove_child(card_ui)
	new_parent.add_child(card_ui)
	
	# Smooth Tween Transition (Cubic-Bezier like easing)
	var new_pos = card_ui.global_position
	card_ui.global_position = old_pos
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_ui, "global_position", new_pos, 0.4)
	
	# Subtle 3D-like rotation during flight
	card_ui.rotation_degrees = 5 if new_pos.x > old_pos.x else -5
	tween.parallel().tween_property(card_ui, "rotation_degrees", 0.0, 0.4)

func _on_sort_btn_pressed():
	# Smart Auto-Sort: Tries to find a valid arrangement automatically
	var cards = []
	for child in hand_container.get_children():
		cards.append(child)
	for row in [head_row, body_row, base_row]:
		for child in row.get_children():
			cards.append(child)
	
	var card_data_list: Array[Card] = []
	for c in cards: card_data_list.append(c.card_data)
	
	# Basic auto-sort strategy: Strongest to base, middle to body, weakest to head
	card_data_list.sort_custom(func(a, b): return a.compare(b) > 0)
	
	_on_reset_btn_pressed() # Move all to hand first
	
	# Simple distribution for the prototype auto-sort
	var base = card_data_list.slice(0, 5)
	var body = card_data_list.slice(5, 10)
	var head = card_data_list.slice(10, 13)
	
	# Find the card UI nodes and move them
	for row_data in [{"row": base_row, "cards": base}, {"row": body_row, "cards": body}, {"row": head_row, "cards": head}]:
		for c_data in row_data.cards:
			for c_ui in hand_container.get_children():
				if c_ui.card_data == c_data:
					_reparent_card(c_ui, row_data.row)
					break
	
	_update_row_labels()
	_show_status("Auto-Sorted!", Color(0.4, 0.8, 1, 1))

func _update_risk_meter():
	# Logic for 'Operational Risk-Meter': Evaluates total hand strength
	var head = _get_cards_from_row(head_row)
	var body = _get_cards_from_row(body_row)
	var base = _get_cards_from_row(base_row)
	
	if head.size() + body.size() + base.size() < 13:
		status_label.text = ""
		return

	var total_rank_sum = HandEvaluator.evaluate(head).rank + HandEvaluator.evaluate(body).rank + HandEvaluator.evaluate(base).rank
	
	if total_rank_sum > 15:
		_show_status("Hand Strength: STRONG", Color(0.2, 1, 0.2, 1))
	elif total_rank_sum > 10:
		_show_status("Hand Strength: BALANCED", Color(1, 0.8, 0.2, 1))
	else:
		_show_status("Hand Strength: WEAK", Color(1, 0.4, 0.4, 1))

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
	_start_showdown_sequence(results)

func _start_showdown_sequence(results):
	# Create a dramatic overlay for comparison
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.theme_override_constants_separation = 30
	overlay.add_child(vbox)
	
	var title = Label.new()
	title.text = "SHOWDOWN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	vbox.add_child(title)
	
	# Staggered reveal of results
	var rows = ["BASE", "BODY", "HEAD"]
	for row_name in rows:
		var l = Label.new()
		l.text = "Comparing %s..." % row_name
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 28)
		vbox.add_child(l)
		await get_tree().create_timer(0.8).timeout
		l.text = row_name + ": COMPLETE"
		l.add_theme_color_override("font_color", Color.GOLD)

	await get_tree().create_timer(0.5).timeout
	
	# Final Result Summary
	var score_text = "Total Points: %d" % results.human_score
	var score_label = Label.new()
	score_label.text = score_text
	score_label.add_theme_font_size_override("font_size", 48)
	score_label.add_theme_color_override("font_color", Color.GREEN if results.human_score >= 0 else Color.RED)
	vbox.add_child(score_label)
	
	if results.human_score >= 6:
		_trigger_pusoy_effect()
		_show_status("PUSOY! Perfect sweep!", Color(1, 0.843, 0, 1))

	var close_btn = Button.new()
	close_btn.text = "CONTINUE"
	close_btn.custom_minimum_size = Vector2(200, 60)
	close_btn.pressed.connect(func(): 
		overlay.queue_free()
		get_tree().reload_current_scene()
	)
	vbox.add_child(close_btn)

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
