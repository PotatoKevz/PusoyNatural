extends Node

# Basic ENet multiplayer setup for LAN
var peer = ENetMultiplayerPeer.new()
const PORT = 4040
const MAX_CLIENTS = 3

signal player_connected(peer_id)
signal player_disconnected(peer_id)
signal server_disconnected

var players = {}
var is_host = false

func host_game():
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		print("Cannot host: ", error)
		return false
	multiplayer.multiplayer_peer = peer
	
	players[1] = "Host"
	is_host = true
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	return true

func join_game(address: String):
	var error = peer.create_client(address, PORT)
	if error != OK:
		print("Cannot join: ", error)
		return false
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	return true

func _on_player_connected(id):
	players[id] = "Player " + str(id)
	player_connected.emit(id)

func _on_player_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = "Me"

func _on_connected_fail():
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()

func close_connection():
	multiplayer.multiplayer_peer = null
	players.clear()
	is_host = false
