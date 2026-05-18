class_name GameplayManager
extends Node

var deck: Deck
var players: Array = []
var active_players: int = 4
var banker_index: int = 0 # 0: Human, 1-3: AI

signal dealing_started
signal cards_dealt
signal round_ended(results: Dictionary)
signal banker_changed(new_banker_id: int)

func start_game():
	_prepare_round()

func _prepare_round():
	deck.reset()
	deck.shuffle()
	
	# Banker rotation: moves clockwise
	banker_index = (GameManager.current_round - 1) % players.size()
	banker_changed.emit(banker_index)
	
	dealing_started.emit()
	
	for player in players:
		player.clear_cards()
		player.receive_cards(deck.deal(13))
		
	cards_dealt.emit()

func submit_hand(player_id: int, head: Array[Card], body: Array[Card], base: Array[Card]):
	if not HandEvaluator.is_valid_arrangement(head, body, base):
		print("Invalid arrangement for player ", player_id)
		return false
	
	players[player_id].set_arranged_hand(head, body, base)
	_check_all_submitted()
	return true

func _check_all_submitted():
	var all_ready = true
	for p in players:
		if not p.is_ready:
			all_ready = false
			break
			
	if all_ready:
		evaluate_round()

func evaluate_round():
	var results = {"human_score": 0, "opponents": []}
	var human = players[0]
	
	for i in range(1, active_players):
		var ai = players[i]
		var match_score = 0
		
		var h_eval = HandEvaluator.evaluate(human.head)
		var m_eval = HandEvaluator.evaluate(human.body)
		var b_eval = HandEvaluator.evaluate(human.base)
		
		var ai_h_eval = HandEvaluator.evaluate(ai.head)
		var ai_m_eval = HandEvaluator.evaluate(ai.body)
		var ai_b_eval = HandEvaluator.evaluate(ai.base)
		
		# Compare Rows (1pt each)
		var h_win = HandEvaluator._compare_evals(h_eval, ai_h_eval)
		var m_win = HandEvaluator._compare_evals(m_eval, ai_m_eval)
		var b_win = HandEvaluator._compare_evals(b_eval, ai_b_eval)
		
		match_score += h_win + m_win + b_win
		
		# Scoop (Pusoy) Check: +3 bonus
		if h_win > 0 and m_win > 0 and b_win > 0:
			match_score += 3
		elif h_win < 0 and m_win < 0 and b_win < 0:
			match_score -= 3
			
		# Bonuses (Guns) - Simple human-only bonus logic for now
		match_score += _calculate_hand_bonuses(h_eval, m_eval, b_eval)
		match_score -= _calculate_hand_bonuses(ai_h_eval, ai_m_eval, ai_b_eval)
		
		results.human_score += match_score
		results.opponents.append({"id": i, "score": -match_score})

	# Update money
	if results.human_score > 0:
		GameManager.add_money(results.human_score * GameManager.current_bet)
		GameManager.record_win()
	elif results.human_score < 0:
		GameManager.deduct_money(abs(results.human_score) * GameManager.current_bet)
		GameManager.record_loss()
		GameManager.check_bankruptcy()
		
	round_ended.emit(results)

func _calculate_hand_bonuses(h, m, b) -> int:
	var bonus = 0
	# Head: 3 of a Kind = 3 pts
	if h.rank == HandEvaluator.HandRank.THREE_OF_A_KIND: bonus += 3
	
	# Body: Full House = 2 pts, 4 of Kind = 8 pts, Straight Flush = 10 pts
	if m.rank == HandEvaluator.HandRank.FULL_HOUSE: bonus += 2
	elif m.rank == HandEvaluator.HandRank.FOUR_OF_A_KIND: bonus += 8
	elif m.rank == HandEvaluator.HandRank.STRAIGHT_FLUSH: bonus += 10
	
	# Base: 4 of Kind = 4 pts, Straight Flush = 5 pts
	if b.rank == HandEvaluator.HandRank.FOUR_OF_A_KIND: bonus += 4
	elif b.rank == HandEvaluator.HandRank.STRAIGHT_FLUSH: bonus += 5
	
	return bonus
