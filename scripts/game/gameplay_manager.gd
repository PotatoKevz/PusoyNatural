class_name GameplayManager
extends Node

var deck: Deck
var players: Array = []
var active_players: int = 4

signal dealing_started
signal cards_dealt
signal round_ended(results: Dictionary)

func _ready():
	deck = Deck.new()

func start_game():
	deck.reset()
	deck.shuffle()
	
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
	# Calculate scores
	var results = {}
	
	# For simplicity, player 0 is human, others are AI
	var human_player = players[0]
	var human_score = 0
	
	for i in range(1, active_players):
		var ai = players[i]
		
		# Compare Head
		var h_res = HandEvaluator._compare_evals(HandEvaluator.evaluate(human_player.head), HandEvaluator.evaluate(ai.head))
		# Compare Body
		var m_res = HandEvaluator._compare_evals(HandEvaluator.evaluate(human_player.body), HandEvaluator.evaluate(ai.body))
		# Compare Base
		var b_res = HandEvaluator._compare_evals(HandEvaluator.evaluate(human_player.base), HandEvaluator.evaluate(ai.base))
		
		# Check Pusoy (win all 3 against a player)
		if h_res > 0 and m_res > 0 and b_res > 0:
			human_score += 3 + 3 # Extra bonus for Pusoy
			print("Pusoy against Player ", i)
		elif h_res < 0 and m_res < 0 and b_res < 0:
			human_score -= (3 + 3)
			print("Got Pusoyed by Player ", i)
		else:
			human_score += h_res + m_res + b_res

	results["human_score"] = human_score
	
	# Update money
	if human_score > 0:
		GameManager.add_money(human_score * GameManager.current_bet)
		GameManager.record_win()
	elif human_score < 0:
		GameManager.deduct_money(abs(human_score) * GameManager.current_bet)
		GameManager.record_loss()
		GameManager.check_bankruptcy()
		
	round_ended.emit(results)
