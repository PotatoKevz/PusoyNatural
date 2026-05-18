class_name Deck
extends RefCounted

var cards: Array[Card] = []

func _init():
	reset()

func reset():
	cards.clear()
	for s in range(4):
		for r in range(2, 15):
			cards.append(Card.new(s as Card.Suit, r as Card.Rank))

func shuffle():
	cards.shuffle()

func draw() -> Card:
	if cards.is_empty():
		return null
	return cards.pop_back()

func deal(num_cards: int) -> Array[Card]:
	var dealt: Array[Card] = []
	for i in range(num_cards):
		var card = draw()
		if card:
			dealt.append(card)
	return dealt
