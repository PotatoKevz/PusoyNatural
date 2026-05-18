class_name AIPlayer
extends PlayerBase

var difficulty: int = 1

func _init(p_id: int, diff: int = 1):
	id = p_id
	difficulty = diff

func receive_cards(new_cards: Array[Card]):
	super.receive_cards(new_cards)
	_arrange_cards_ai()

func _arrange_cards_ai():
	# Simple AI for prototype: just split the 13 cards randomly but ensure validity.
	# A real implementation would evaluate all combinations and pick the strongest.
	var sorted = cards.duplicate()
	sorted.sort_custom(func(a, b): return a.compare(b) > 0)
	
	# Try random valid configurations
	var max_attempts = 100
	for i in range(max_attempts):
		var temp = sorted.duplicate()
		temp.shuffle()
		
		var t_base = temp.slice(0, 5)
		var t_body = temp.slice(5, 10)
		var t_head = temp.slice(10, 13)
		
		if HandEvaluator.is_valid_arrangement(t_head, t_body, t_base):
			set_arranged_hand(t_head, t_body, t_base)
			return
			
	# Fallback (Very poor arrangement but valid)
	# Sort ascending. Head = 3 weakest. Body = next 5. Base = 5 strongest.
	sorted.sort_custom(func(a, b): return a.compare(b) < 0)
	set_arranged_hand(sorted.slice(0, 3), sorted.slice(3, 8), sorted.slice(8, 13))
