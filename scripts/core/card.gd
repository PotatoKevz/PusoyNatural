class_name Card
extends Resource

enum Suit { CLUBS = 0, DIAMONDS = 1, HEARTS = 2, SPADES = 3 }
enum Rank {
	TWO = 2, THREE = 3, FOUR = 4, FIVE = 5, SIX = 6, SEVEN = 7,
	EIGHT = 8, NINE = 9, TEN = 10, JACK = 11, QUEEN = 12, KING = 13, ACE = 14
}

@export var suit: Suit
@export var rank: Rank
@export var texture: Texture2D

func _init(p_suit: Suit = Suit.CLUBS, p_rank: Rank = Rank.TWO):
	suit = p_suit
	rank = p_rank

func get_card_name() -> String:
	var rank_str = str(rank)
	match rank:
		Rank.JACK: rank_str = "J"
		Rank.QUEEN: rank_str = "Q"
		Rank.KING: rank_str = "K"
		Rank.ACE: rank_str = "A"
	
	var suit_str = ""
	match suit:
		Suit.CLUBS: suit_str = "C"
		Suit.DIAMONDS: suit_str = "D"
		Suit.HEARTS: suit_str = "H"
		Suit.SPADES: suit_str = "S"
		
	return rank_str + suit_str

func get_value() -> int:
	return rank

func compare(other: Card) -> int:
	if rank > other.rank:
		return 1
	elif rank < other.rank:
		return -1
	else:
		if suit > other.suit:
			return 1
		elif suit < other.suit:
			return -1
		return 0
