class_name CardUI
extends Control

@onready var rank_label = $Background/Rank
@onready var suit_small = $Background/SuitSmall
@onready var suit_large = $Background/SuitLarge
@onready var rank_bottom = $Background/BottomCorner/RankBottom
@onready var suit_bottom = $Background/BottomCorner/SuitBottom
@onready var background = $Background
@onready var back_view = $Back
@onready var selection_highlight = $SelectionHighlight

var card_data: Card

func setup(p_card: Card):
	card_data = p_card

	var rank_text = str(card_data.rank)
	match card_data.rank:
		Card.Rank.JACK: rank_text = "J"
		Card.Rank.QUEEN: rank_text = "Q"
		Card.Rank.KING: rank_text = "K"
		Card.Rank.ACE: rank_text = "A"

	var suit_text = ""
	var color = Color.BLACK
	match card_data.suit:
		Card.Suit.CLUBS: suit_text = "♣"
		Card.Suit.DIAMONDS:
			suit_text = "♦"
			color = Color(0.85, 0.05, 0.05, 1)
		Card.Suit.HEARTS:
			suit_text = "♥"
			color = Color(0.85, 0.05, 0.05, 1)
		Card.Suit.SPADES: suit_text = "♠"

	rank_label.text = rank_text
	rank_label.add_theme_color_override("font_color", color)
	suit_small.text = suit_text
	suit_small.add_theme_color_override("font_color", color)
	suit_large.text = suit_text
	suit_large.add_theme_color_override("font_color", color)
	rank_bottom.text = rank_text
	rank_bottom.add_theme_color_override("font_color", color)
	suit_bottom.text = suit_text
	suit_bottom.add_theme_color_override("font_color", color)

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pivot_offset = size / 2

func _on_mouse_entered():
	# Elegant Hover: Scale up slightly and add a subtle glow/shadow
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.2)
	z_index = 10 # Bring to front when hovering

func _on_mouse_exited():
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	z_index = 0

func set_selected(selected: bool):
	selection_highlight.visible = selected
	if selected:
		# Selection Pulse
		var tween = create_tween().set_loops(2)
		tween.tween_property(background, "modulate", Color(1.2, 1.2, 1.2, 1), 0.1)
		tween.tween_property(background, "modulate", Color.WHITE, 0.1)

func _get_drag_data(_at_position):
	var preview = duplicate()
	preview.modulate.a = 0.5
	set_drag_preview(preview)
	return self

func _can_drop_data(_at_position, data):
	return data is CardUI
