class_name AIPlayer
extends PlayerBase

var difficulty: int = 1

enum Personality { CONSERVATIVE, AGGRESSIVE }
var personality: Personality = Personality.CONSERVATIVE

func _init(p_id: int, diff: int = 1):
	id = p_id
	difficulty = diff
	# Assign personality based on difficulty or random
	personality = Personality.AGGRESSIVE if randf() > 0.5 else Personality.CONSERVATIVE

func receive_cards(new_cards: Array[Card]):
	super.receive_cards(new_cards)
	_arrange_cards_ai()

func _arrange_cards_ai():
	var sorted = cards.duplicate()
	sorted.sort_custom(func(a, b): return a.compare(b) > 0)
	
	if personality == Personality.AGGRESSIVE:
		_arrange_aggressive(sorted)
	else:
		_arrange_conservative(sorted)

func _arrange_aggressive(sorted: Array[Card]):
	# Aggressive: Try to build the absolute strongest Base hand possible first
	var temp = sorted.duplicate()
	var base = temp.slice(0, 5) # Top 5
	var body = temp.slice(5, 10) # Next 5
	var head = temp.slice(10, 13) # Last 3
	
	if HandEvaluator.is_valid_arrangement(head, body, base):
		set_arranged_hand(head, body, base)
	else:
		# Fallback to random valid search
		_arrange_random_valid(sorted)

func _arrange_conservative(sorted: Array[Card]):
	# Conservative: Try to put strength in the Middle and Head to avoid sweeps
	var temp = sorted.duplicate()
	# Distribution: 4 strongest to Base, 5 next to Body, then 1 strongest to Head
	var base = [temp[4], temp[5], temp[6], temp[7], temp[8]]
	var body = [temp[0], temp[1], temp[2], temp[3], temp[9]]
	var head = [temp[10], temp[11], temp[12]]
	
	if HandEvaluator.is_valid_arrangement(head, body, base):
		set_arranged_hand(head, body, base)
	else:
		_arrange_random_valid(sorted)

func _arrange_random_valid(sorted: Array[Card]):
	var max_attempts = 200
	for i in range(max_attempts):
		var temp = sorted.duplicate()
		temp.shuffle()
		var t_base = temp.slice(0, 5)
		var t_body = temp.slice(5, 10)
		var t_head = temp.slice(10, 13)
		if HandEvaluator.is_valid_arrangement(t_head, t_body, t_base):
			set_arranged_hand(t_head, t_body, t_base)
			return
	
	# Ultimate fallback: guaranteed valid
	var s_asc = sorted.duplicate()
	s_asc.sort_custom(func(a, b): return a.compare(b) < 0)
	set_arranged_hand(s_asc.slice(0, 3), s_asc.slice(3, 8), s_asc.slice(8, 13))
