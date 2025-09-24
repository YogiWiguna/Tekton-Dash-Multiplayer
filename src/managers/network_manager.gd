extends Node

# Signal emitted when the connection to the server is established or fails
signal connection_result(success)
# Signal emitted when the list of players is updated
signal players_changed(players)
# Signal emitted when the game state is received from the host
signal game_state_received(state)

const DEFAULT_PORT = 8910
var peer = ENetMultiplayerPeer.new()
var players = {}
# This will store the authoritative game state from the host.
var current_game_state = {}

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func create_server(player_name: String):
	peer.create_server(DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(peer)
	# The host is always player number 1
	players[1] = {"name": player_name, "id": 1, "player_number": 1}
	# We emit the signal here so the host can spawn their own character
	emit_signal("players_changed", players)
	print("Server created. Player '%s' added as Player 1." % player_name)

func join_server(player_name: String, ip_address: String):
	var ip = ip_address if ip_address else "127.0.0.1"
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(peer)

func get_player_list():
	"""Returns a list of player names."""
	return players.values().map(func(p): return p.name)

func _on_player_connected(id: int):
	print("Player %d connected." % id)
	# The new player will RPC the server to introduce themselves.

func _on_player_disconnected(id: int):
	if players.has(id):
		var player_name = players[id].name
		players.erase(id)
		print("Player %s (%d) disconnected." % [player_name, id])
		rpc("_update_player_list", players)
		emit_signal("players_changed", players)

func _on_connected_to_server():
	print("Successfully connected to the server.")
	rpc_id(1, "_register_player", PlayerData.player_name)
	emit_signal("connection_result", true)

func _on_connection_failed():
	print("Failed to connect to the server.")
	multiplayer.set_multiplayer_peer(null)
	emit_signal("connection_result", false)

func _on_server_disconnected():
	print("Disconnected from the server.")
	multiplayer.set_multiplayer_peer(null)
	players.clear()
	emit_signal("players_changed", players)
	get_tree().change_scene_to_file("res://scenes/network/network.tscn")

@rpc("any_peer", "call_local")
func _register_player(player_name: String):
	var new_player_id = multiplayer.get_remote_sender_id()
	var new_player_number = players.size() + 1
	players[new_player_id] = {"name": player_name, "id": new_player_id, "player_number": new_player_number}
	
	# 1. Tell EVERYONE the player list has updated. This spawns the NEW player.
	rpc("_update_player_list", players)
	
	# 2. CATCH-UP LOGIC: Tell the new player about everyone who was already here.
	var main_node = get_node("/root/Main")
	for player_id in players:
		if player_id != new_player_id:
			var p_data = players[player_id]
			if main_node.spawned_players.has(player_id):
				var existing_player_node = main_node.spawned_players[player_id]
				var current_position = existing_player_node.global_transform.origin
				var current_floor = existing_player_node.current_player_floor_id
				
				# Send a targeted command ONLY to the new client to spawn an existing player.
				main_node.spawn_player_on_clients.rpc_id(new_player_id, p_data, current_position, current_floor)

	# 3. Send the game world data to the new player.
	if not current_game_state.is_empty():
		rpc_id(new_player_id, "receive_game_state", current_game_state)

@rpc("any_peer", "call_local")
func _update_player_list(new_player_list):
	players = new_player_list
	emit_signal("players_changed", players)

# Called by the host from main.gd
func sync_game_state(state_data: Dictionary):
	if not multiplayer.is_server(): return
	current_game_state = state_data
	# Note: We don't RPC from here. We send it specifically to new players when they register.
	print("Host is caching game state.")

@rpc("any_peer", "call_local")
func receive_game_state(state_data: Dictionary):
	# The host calls this on itself, so we don't need to check if it's the server.
	print("Peer %d received game state." % multiplayer.get_unique_id())
	emit_signal("game_state_received", state_data)
