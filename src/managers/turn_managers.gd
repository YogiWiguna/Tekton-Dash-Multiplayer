# src/managers/turn_manager.gd
extends Node

# This node is the single source of truth for whose turn it is.
# It is controlled only by the host/server.

@onready var main = get_node("/root/Main")
@onready var network_manager = get_node("/root/NetworkManager")

var player_turn_order: Array = []

func _ready():
	network_manager.players_changed.connect(_on_players_changed)

func _on_players_changed(players: Dictionary):
	if not multiplayer.is_server(): return

	var players_with_numbers = []
	for id in players:
		var p_data = players[id]
		players_with_numbers.append({"id": id, "player_number": p_data.get("player_number", 0)})
	
	# Sort players by their join number to create a stable turn order
	players_with_numbers.sort_custom(func(a, b): return a.player_number < b.player_number)
	player_turn_order = players_with_numbers.map(func(p): return p.id)

	print("Turn order updated: ", player_turn_order)
	if not main.game_started and not player_turn_order.is_empty():
		start_game()

# Called by the host from main.gd after the world is built and players are spawned.
func start_game():
	print("Game is starting with turn order: ", player_turn_order)
	await get_tree().create_timer(1.0).timeout
	start_next_turn()

# This function, called only by the host, determines and broadcasts the next player.
func start_next_turn():
	if not multiplayer.is_server() or player_turn_order.is_empty(): return

	main.player_actions = -1 

	var next_player_id = -1
	var current_player_index = player_turn_order.find(main.current_turn_player_id)

	var next_player_index
	if current_player_index == -1:
		next_player_index = 0
	else:
		next_player_index = (current_player_index + 1) % player_turn_order.size()
	
	next_player_id = player_turn_order[next_player_index]

	var new_round = main.current_round
	if next_player_index == 0:
		new_round += 1

	if next_player_id != -1:
		main.set_current_turn_globally.rpc(next_player_id, new_round)

# This RPC is called on all clients to update the game state for the new turn.
@rpc("any_peer", "call_local")
func set_current_turn(player_id: int):
	if main.spawned_players.has(player_id):
		main.current_player_node = main.spawned_players[player_id]
		main.player_actions = 2
		
		main.characters_manager.update_valid_moves(main.current_player_node)
		# Call the function on the player script to reset its state and show the GUI.
		main.current_player_node.start_turn()
		print("It is now Player %d's turn." % player_id)
	else:
		print("Error: Could not find player with ID %d to start turn." % player_id)

# This is the central function to check if an action is allowed.
func is_local_players_turn() -> bool:
	if not main.game_started or main.current_turn_player_id == -1:
		return false
	
	return multiplayer.get_unique_id() == main.current_turn_player_id
