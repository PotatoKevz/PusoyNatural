extends Control

@onready var hand_container = $HandArea/Cards
@onready var head_row = $HeadRow
@onready var body_row = $BodyRow
@onready var base_row = $BaseRow
@onready var money_label = $TopUI/MoneyLabel

var card_ui_scene = preload("res://scenes/card_ui.tscn")
var gameplay_manager: GameplayManager

func _ready():
	gameplay_manager = GameplayManager.new()
	add_child(gameplay_manager)
	
	gameplay_manager.cards_dealt.connect(_on_cards_dealt)
	gameplay_manager.round_ended.connect(_on_round_ended)
	
	_apply_tier_visuals()
	_update_ui()
	
	_setup_players()
	gameplay_manager.start_game()

func _apply_tier_visuals():
	match GameManager.current_table_tier:
		GameManager.TableTier.LOW:
			$Table/Felt.color = Color(0.06, 0.19, 0.06, 0.3) # Simple Green
		GameManager.TableTier.MEDIUM:
			$Table/Felt.color = Color(0.1, 0.1, 0.3, 0.5) # Metallic Blue
			# Add glow or other effects
		GameManager.TableTier.HIGH:
			$Table/Felt.color = Color(0.2, 0.1, 0, 0.6) # Luxury Gold/Brown
			# Intense effects

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

func _update_ui():
	money_label.text = "$ " + str(GameManager.current_money)

func _on_card_gui_input(event, card_ui):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_move_card(card_ui)

func _move_card(card_ui):
	var current_parent = card_ui.get_parent()
	
	if current_parent == hand_container:
		# Move to first available row
		if head_row.get_child_count() < 3:
			_reparent_card(card_ui, head_row)
		elif body_row.get_child_count() < 5:
			_reparent_card(card_ui, body_row)
		elif base_row.get_child_count() < 5:
			_reparent_card(card_ui, base_row)
	else:
		# Move back to hand
		_reparent_card(card_ui, hand_container)

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

func _on_submit_btn_pressed():
	if head_row.get_child_count() != 3 or body_row.get_child_count() != 5 or base_row.get_child_count() != 5:
		print("Arrange all 13 cards first!")
		return
		
	var head = _get_cards_from_row(head_row)
	var body = _get_cards_from_row(body_row)
	var base = _get_cards_from_row(base_row)
	
	if gameplay_manager.submit_hand(0, head, body, base):
		print("Hand submitted successfully!")
	else:
		print("Invalid Hand! Remember: Head < Body < Base")

func _get_cards_from_row(row):
	var cards: Array[Card] = []
	for child in row.get_children():
		cards.append(child.card_data)
	return cards

var pusoy_effect_scene = preload("res://scenes/effects/pusoy_effect.tscn")

func _on_round_ended(results):
	print("Round Over! Score: ", results.human_score)
	_update_ui()
	
	if results.human_score >= 6: # Pusoy bonus
		_trigger_pusoy_effect()

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
