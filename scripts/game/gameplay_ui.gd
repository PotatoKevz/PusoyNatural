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
var _selected_card_ui: CardUI = null # For tap-to-swap
var _player_seat_index: int = 0 # 0-3

func _ready():
	gameplay_manager = GameplayManager.new()
	add_child(gameplay_manager)

	gameplay_manager.cards_dealt.connect(_on_cards_dealt)
	gameplay_manager.round_ended.connect(_on_round_ended)
	gameplay_manager.banker_changed.connect(_on_banker_changed)

	_apply_tier_visuals()
	_update_ui()
	
	_show_seat_selection()

func _show_seat_selection():
	var overlay = ColorRect.new()
	overlay.name = "SeatSelection"
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var label = Label.new()
	label.text = "CHOOSE YOUR SEAT"
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.position.y += 100
	label.add_theme_font_size_override("font_size", 48)
	overlay.add_child(label)
	
	# Create 4 seat buttons
	var seat_data = [
		{"name": "SOUTH", "pos": Vector2(0.5, 0.75), "idx": 0},
		{"name": "WEST", "pos": Vector2(0.2, 0.5), "idx": 1},
		{"name": "NORTH", "pos": Vector2(0.5, 0.25), "idx": 2},
		{"name": "EAST", "pos": Vector2(0.8, 0.5), "idx": 3}
	]
	
	for s in seat_data:
		var btn = Button.new()
		btn.text = s["name"]
		btn.custom_minimum_size = Vector2(200, 100)
		btn.set_anchors_preset(Control.PRESET_CENTER)
		btn.anchor_left = s["pos"].x
		btn.anchor_top = s["pos"].y
		btn.anchor_right = s["pos"].x
		btn.anchor_bottom = s["pos"].y
		btn.offset_left = -100
		btn.offset_top = -50
		btn.pressed.connect(func():
			_player_seat_index = s["idx"]
			overlay.queue_free()
			_setup_players()
			gameplay_manager.start_game()
		)
		overlay.add_child(btn)

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
	# Clear old cards from all areas
	for child in hand_container.get_children(): child.queue_free()
	for row in [head_row, body_row, base_row]:
		for child in row.get_children(): child.queue_free()
	
	await get_tree().process_frame # Wait for cleanup
	
	var human = gameplay_manager.players[0]
	for card in human.cards:
		var card_ui = card_ui_scene.instantiate()
		hand_container.add_child(card_ui)
		card_ui.setup(card)
		card_ui.gui_input.connect(_on_card_gui_input.bind(card_ui))
	
	_update_row_labels()
	_show_opponents()

func _show_opponents():
	# Display opponents at their respective seats
	for i in range(1, 4):
		var node_name = "OpponentSlot_%d" % i
		if not has_node(node_name):
			var slot = Panel.new()
			slot.name = node_name
			slot.custom_minimum_size = Vector2(120, 120)
			# Distribute around table (relative to player seat)
			var seat_idx = (i + _player_seat_index) % 4
			_position_slot_at_seat(slot, seat_idx)
			add_child(slot)
			
			var lbl = Label.new()
			lbl.text = "Opponent %d" % i
			lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot.add_child(lbl)

func _position_slot_at_seat(node: Control, seat_idx: int):
	node.set_anchors_preset(Control.PRESET_CENTER)
	match seat_idx:
		0: # SOUTH (Bottom)
			node.anchor_top = 0.85
			node.anchor_bottom = 0.85
		1: # WEST (Left)
			node.anchor_left = 0.1
			node.anchor_right = 0.1
		2: # NORTH (Top)
			node.anchor_top = 0.15
			node.anchor_bottom = 0.15
		3: # EAST (Right)
			node.anchor_left = 0.9
			node.anchor_right = 0.9
	node.offset_left = -60
	node.offset_top = -60

# ── UI Updates ────────────────────────────────────────────────────────────────

func _update_ui():
	money_label.text = "$ " + _format_money(GameManager.current_money)
	bet_label.text = "Bet: $" + str(GameManager.current_bet)
	# Update Round Indicator
	if has_node("TopUI/RoundLabel"):
		get_node("TopUI/RoundLabel").text = "Round: %d/%d" % [GameManager.current_round, GameManager.session_rounds]

func _on_banker_changed(banker_id: int):
	var banker_name = "YOU" if banker_id == 0 else "Player %d" % banker_id
	_show_status("Banker: %s" % banker_name, Color.GOLD)

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
			_handle_card_tap(card_ui)

func _handle_card_tap(card_ui: CardUI):
	if _selected_card_ui == null:
		# First tap: Select
		_selected_card_ui = card_ui
		_selected_card_ui.set_selected(true)
	elif _selected_card_ui == card_ui:
		# Tap same card: Deselect
		_selected_card_ui.set_selected(false)
		_selected_card_ui = null
	else:
		# Second tap different card: Swap
		_swap_cards(_selected_card_ui, card_ui)
		_selected_card_ui.set_selected(false)
		_selected_card_ui = null

func _swap_cards(card_a: CardUI, card_b: CardUI):
	var parent_a = card_a.get_parent()
	var parent_b = card_b.get_parent()
	var idx_a = card_a.get_index()
	var idx_b = card_b.get_index()
	
	var pos_a = card_a.global_position
	var pos_b = card_b.global_position
	
	# Physically swap parents and indices
	if parent_a == parent_b:
		parent_a.move_child(card_a, idx_b)
		parent_a.move_child(card_b, idx_a)
	else:
		parent_a.remove_child(card_a)
		parent_b.remove_child(card_b)
		parent_a.add_child(card_b)
		parent_a.move_child(card_b, idx_a)
		parent_b.add_child(card_a)
		parent_b.move_child(card_a, idx_b)
	
	# Animate swap
	card_a.global_position = pos_a
	card_b.global_position = pos_b
	
	var tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_a, "global_position", pos_b, 0.3)
	tween.tween_property(card_b, "global_position", pos_a, 0.3)
	
	_update_row_labels()

func _reparent_card(card_ui, new_parent):
	var old_pos = card_ui.global_position
	card_ui.get_parent().remove_child(card_ui)
	new_parent.add_child(card_ui)
	
	# Wait for layout engine to calculate new position
	new_parent.queue_sort()
	await get_tree().process_frame
	
	var new_pos = card_ui.global_position
	card_ui.global_position = old_pos
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_ui, "global_position", new_pos, 0.3)
	
	# Subtle 3D-like rotation during flight
	card_ui.rotation_degrees = 5 if new_pos.x > old_pos.x else -5
	tween.parallel().tween_property(card_ui, "rotation_degrees", 0.0, 0.3)

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
	_start_professional_showdown(results)

func _start_professional_showdown(results):
	_show_status("SHOWDOWN START!", Color.GOLD)
	
	# Banker reveals first
	var banker_p = gameplay_manager.players[gameplay_manager.banker_index]
	var banker_label = "YOU (Banker)" if gameplay_manager.banker_index == 0 else "Player %d (Banker)" % gameplay_manager.banker_index
	_show_status("Banker Reveal: %s" % banker_label, Color.GOLD)
	
	await _reveal_player_hand(gameplay_manager.banker_index)
	await get_tree().create_timer(1.0).timeout
	
	# Then reveal others row by row
	for i in range(gameplay_manager.active_players):
		if i == gameplay_manager.banker_index: continue
		var p_label = "YOU" if i == 0 else "Player %d" % i
		_show_status("Revealing: %s" % p_label, Color.CYAN)
		await _reveal_player_hand(i)
		await get_tree().create_timer(0.5).timeout

	# Show Summary Overlay
	_show_final_summary(results)

func _reveal_player_hand(p_idx: int):
	var player = gameplay_manager.players[p_idx]
	var seat_idx = (p_idx + _player_seat_index) % 4
	
	# Create a temporary display for this player's reveal
	var reveal_node = Control.new()
	reveal_node.name = "Reveal_P%d" % p_idx
	add_child(reveal_node)
	
	# Position the reveal area near their seat
	_position_slot_at_seat(reveal_node, seat_idx)
	reveal_node.offset_top -= 150 # Move up a bit to show cards
	
	var rows = [
		{"name": "BASE", "cards": player.base, "off": Vector2(0, 0)},
		{"name": "BODY", "cards": player.body, "off": Vector2(0, -60)},
		{"name": "HEAD", "cards": player.head, "off": Vector2(0, -120)}
	]
	
	for r_data in rows:
		var row_container = HBoxContainer.new()
		row_container.position = r_data["off"]
		reveal_node.add_child(row_container)
		
		for c in r_data["cards"]:
			var card_ui = card_ui_scene.instantiate()
			row_container.add_child(card_ui)
			card_ui.setup(c)
			card_ui.scale = Vector2(0.4, 0.4) # Smaller for table reveal
			card_ui.set_face_up(true)
		
		await get_tree().create_timer(0.4).timeout

func _show_final_summary(results):
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.9)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	overlay.add_child(vbox)
	
	var t = Label.new()
	t.text = "ROUND COMPLETE"
	t.add_theme_font_size_override("font_size", 56)
	vbox.add_child(t)
	
	var s = Label.new()
	s.text = "Total Score: %d" % results.human_score
	s.add_theme_font_size_override("font_size", 42)
	s.add_theme_color_override("font_color", Color.GREEN if results.human_score >= 0 else Color.RED)
	vbox.add_child(s)
	
	if results.get("got_scooped", false):
		var scoop_lbl = Label.new()
		scoop_lbl.text = "PUSOY!" if results.human_score > 0 else "PUSOYED!"
		scoop_lbl.add_theme_color_override("font_color", Color.GOLD if results.human_score > 0 else Color.RED)
		vbox.add_child(scoop_lbl)
	
	var btn = Button.new()
	btn.text = "CONTINUE"
	btn.custom_minimum_size = Vector2(200, 60)
	btn.pressed.connect(func():
		overlay.queue_free()
		# Clean up reveals
		for i in range(4):
			if has_node("Reveal_P%d" % i): get_node("Reveal_P%d" % i).queue_free()
			
		if GameManager.current_round >= GameManager.session_rounds:
			_show_session_summary()
		else:
			GameManager.current_round += 1
			get_tree().reload_current_scene()
	)
	vbox.add_child(btn)

func _show_session_summary():
	var summary = ColorRect.new()
	summary.color = Color(0, 0, 0, 0.95)
	summary.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(summary)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.theme_override_constants_separation = 20
	summary.add_child(vbox)
	
	var title = Label.new()
	title.text = "SESSION COMPLETE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	vbox.add_child(title)
	
	var exit_btn = Button.new()
	exit_btn.text = "BACK TO LOBBY"
	exit_btn.custom_minimum_size = Vector2(300, 80)
	exit_btn.pressed.connect(func(): 
		GameManager.current_round = 1
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(exit_btn)

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
