class_name HandEvaluator
extends RefCounted

enum HandRank {
	HIGH_CARD = 1,
	PAIR = 2,
	TWO_PAIR = 3,
	THREE_OF_A_KIND = 4,
	STRAIGHT = 5,
	FLUSH = 6,
	FULL_HOUSE = 7,
	FOUR_OF_A_KIND = 8,
	STRAIGHT_FLUSH = 9,
	ROYAL_FLUSH = 10
}

# Evaluate a hand of 3 or 5 cards
static func evaluate(cards: Array[Card]) -> Dictionary:
	if cards.size() != 3 and cards.size() != 5:
		return {"rank": HandRank.HIGH_CARD, "value": 0, "cards": cards}
		
	var sorted_cards = cards.duplicate()
	sorted_cards.sort_custom(func(a, b): return a.compare(b) > 0) # Sort descending
	
	if cards.size() == 3:
		return _evaluate_3_card(sorted_cards)
	else:
		return _evaluate_5_card(sorted_cards)

static func _evaluate_3_card(cards: Array[Card]) -> Dictionary:
	var counts = _get_rank_counts(cards)
	
	if counts.values().has(3):
		return {"rank": HandRank.THREE_OF_A_KIND, "value": cards[0].rank, "cards": cards}
	
	if counts.values().has(2):
		var pair_rank = 0
		for r in counts:
			if counts[r] == 2:
				pair_rank = r
		return {"rank": HandRank.PAIR, "value": pair_rank, "cards": cards}
		
	return {"rank": HandRank.HIGH_CARD, "value": cards[0].rank, "cards": cards}

static func _evaluate_5_card(cards: Array[Card]) -> Dictionary:
	var is_flush = _check_flush(cards)
	var is_straight = _check_straight(cards)
	var counts = _get_rank_counts(cards)
	
	if is_straight and is_flush:
		if cards[0].rank == Card.Rank.ACE and cards[1].rank == Card.Rank.KING:
			return {"rank": HandRank.ROYAL_FLUSH, "value": cards[0].rank, "cards": cards}
		return {"rank": HandRank.STRAIGHT_FLUSH, "value": cards[0].rank, "cards": cards}
		
	if counts.values().has(4):
		var quad_rank = 0
		for r in counts:
			if counts[r] == 4: quad_rank = r
		return {"rank": HandRank.FOUR_OF_A_KIND, "value": quad_rank, "cards": cards}
		
	if counts.values().has(3) and counts.values().has(2):
		var trio_rank = 0
		for r in counts:
			if counts[r] == 3: trio_rank = r
		return {"rank": HandRank.FULL_HOUSE, "value": trio_rank, "cards": cards}
		
	if is_flush:
		return {"rank": HandRank.FLUSH, "value": cards[0].rank, "cards": cards}
		
	if is_straight:
		# Handle A-2-3-4-5 low straight
		var high_card = cards[0].rank
		if cards[0].rank == Card.Rank.ACE and cards[1].rank == Card.Rank.FIVE:
			high_card = cards[1].rank
		return {"rank": HandRank.STRAIGHT, "value": high_card, "cards": cards}
		
	if counts.values().has(3):
		var trio_rank = 0
		for r in counts:
			if counts[r] == 3: trio_rank = r
		return {"rank": HandRank.THREE_OF_A_KIND, "value": trio_rank, "cards": cards}
		
	var pair_count = 0
	var highest_pair = 0
	for r in counts:
		if counts[r] == 2:
			pair_count += 1
			if r > highest_pair: highest_pair = r
			
	if pair_count == 2:
		return {"rank": HandRank.TWO_PAIR, "value": highest_pair, "cards": cards}
		
	if pair_count == 1:
		return {"rank": HandRank.PAIR, "value": highest_pair, "cards": cards}
		
	return {"rank": HandRank.HIGH_CARD, "value": cards[0].rank, "cards": cards}

static func _get_rank_counts(cards: Array[Card]) -> Dictionary:
	var counts = {}
	for card in cards:
		if not counts.has(card.rank):
			counts[card.rank] = 0
		counts[card.rank] += 1
	return counts

static func _check_flush(cards: Array[Card]) -> bool:
	var first_suit = cards[0].suit
	for i in range(1, cards.size()):
		if cards[i].suit != first_suit:
			return false
	return true

static func _check_straight(cards: Array[Card]) -> bool:
	var is_straight = true
	for i in range(cards.size() - 1):
		if cards[i].rank != cards[i+1].rank + 1:
			is_straight = false
			break
			
	# Check low straight A-5-4-3-2
	if not is_straight and cards[0].rank == Card.Rank.ACE:
		if cards[1].rank == Card.Rank.FIVE and cards[2].rank == Card.Rank.FOUR and cards[3].rank == Card.Rank.THREE and cards[4].rank == Card.Rank.TWO:
			return true
			
	return is_straight

# Validates if Head < Body < Base
static func is_valid_arrangement(head: Array[Card], body: Array[Card], base: Array[Card]) -> bool:
	var h_eval = evaluate(head)
	var m_eval = evaluate(body)
	var b_eval = evaluate(base)
	
	if _compare_evals(m_eval, h_eval) < 0:
		return false
	if _compare_evals(b_eval, m_eval) < 0:
		return false
		
	return true

static func _compare_evals(eval1: Dictionary, eval2: Dictionary) -> int:
	if eval1.rank > eval2.rank:
		return 1
	elif eval1.rank < eval2.rank:
		return -1
	else:
		if eval1.value > eval2.value:
			return 1
		elif eval1.value < eval2.value:
			return -1
			
		# Compare kickers
		for i in range(eval1.cards.size()):
			if i < eval2.cards.size():
				if eval1.cards[i].rank > eval2.cards[i].rank: return 1
				if eval1.cards[i].rank < eval2.cards[i].rank: return -1
		return 0
