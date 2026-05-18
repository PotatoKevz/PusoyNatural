class_name PlayerBase
extends Node

var id: int
var cards: Array[Card] = []
var head: Array[Card] = []
var body: Array[Card] = []
var base: Array[Card] = []
var is_ready: bool = false

func clear_cards():
	cards.clear()
	head.clear()
	body.clear()
	base.clear()
	is_ready = false

func receive_cards(new_cards: Array[Card]):
	cards = new_cards
	# Automatically arrange for AI or wait for Human

func set_arranged_hand(h: Array[Card], m: Array[Card], b: Array[Card]):
	head = h
	body = m
	base = b
	is_ready = true
