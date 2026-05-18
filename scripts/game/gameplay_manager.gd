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
	var results = {"human_score": 0, "opponents": [], "got_scooped": false}
	
	# Banker Rules: 
	# - If Human is Banker: Compare vs all 3 AI
	# - If AI is Banker: Human only compares vs that AI
	
	if banker_index == 0: # Human is Banker
		for i in range(1, active_players):
			var res = _compare_two_players(0, i)
			results.human_score += res.score
			results.opponents.append({"id": i, "score": -res.score})
			if res.scooped: results.got_scooped = true # In this case, human scooped the AI
	else: # AI is Banker
		var res = _compare_two_players(0, banker_index)
		results.human_score = res.score
		results.opponents.append({"id": banker_index, "score": -res.score})
		if res.scooped and res.score < 0:
			results.got_scooped = true # Human got scooped by the AI Banker

	# Update money
	if results.human_score > 0:
		GameManager.add_money(results.human_score * GameManager.current_bet)
		GameManager.record_win()
	elif results.human_score < 0:
		GameManager.deduct_money(abs(results.human_score) * GameManager.current_bet)
		GameManager.record_loss()
		GameManager.check_bankruptcy()
		
	round_ended.emit(results)

func _compare_two_players(p1_idx: int, p2_idx: int) -> Dictionary:
	var p1 = players[p1_idx]
	var p2 = players[p2_idx]
	var score = 0
	var scooped = false
	
	var p1_h = HandEvaluator.evaluate(p1.head)
	var p1_m = HandEvaluator.evaluate(p1.body)
	var p1_b = HandEvaluator.evaluate(p1.base)
	
	var p2_h = HandEvaluator.evaluate(p2.head)
	var p2_m = HandEvaluator.evaluate(p2.body)
	var p2_b = HandEvaluator.evaluate(p2.base)
	
	var h_win = HandEvaluator._compare_evals(p1_h, p2_h)
	var m_win = HandEvaluator._compare_evals(p1_m, p2_m)
	var b_win = HandEvaluator._compare_evals(p1_b, p2_b)
	
	score += h_win + m_win + b_win
	
	# Scoop (Pusoy) Check: +3 bonus
	if h_win > 0 and m_win > 0 and b_win > 0:
		score += 3
		scooped = true
	elif h_win < 0 and m_win < 0 and b_win < 0:
		score -= 3
		scooped = true
		
	# Guns (Hand Bonuses)
	score += _calculate_hand_bonuses(p1_h, p1_m, p1_b)
	score -= _calculate_hand_bonuses(p2_h, p2_m, p2_b)
	
	return {"score": score, "scooped": scooped}

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
