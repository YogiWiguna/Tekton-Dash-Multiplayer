extends Node3D

signal world_build_complete

@export var current_level_id : int = 1 
@export var player_scene: PackedScene = preload("res://scenes/player/player_0.tscn")

# Variables for size of arena
var player_number : int = 4 # Default for player number is 4
var default_rows : int = 10 # Default for rows is 10

# Variable for player actions
var player_actions : int = 2 

@onready var network_manager = get_node_or_null("/root/NetworkManager")
@onready var floors_and_tiles_manager = $FloorsAndTileManager
@onready var obstacles_manager = $Obstacles
@onready var characters_manager = $CharactersManager
@onready var turn_manager = $TurnManager
@onready var round_label = $Gui/RoundLabel

var current_game_state = {}
var spawned_players = {}

var current_player_node = null
var current_turn_player_id: int = -1

var start_positions = { 1: 1, 2: 2, 3: 0, 4: 3 }
var initial_state_generated = false

var world_built = false
var game_started: bool = false

var current_round: int = 0

# Variables to queue a turn change if it arrives too early.
var queued_turn_id: int = -1
var queued_round: int = -1

func _ready():
	network_manager.game_state_received.connect(receive_game_state)
	network_manager.players_changed.connect(update_player_spawns)

	# Host generates the world state immediately upon entering the scene.
	if multiplayer.is_server() and not initial_state_generated:
		initial_state_generated = true
		var initial_state = {
			"player_number": player_number,
			"default_rows": default_rows,
			"tiles": floors_and_tiles_manager.generate_random_tile_data(),
			"obstacles": obstacles_manager.generate_obstacle_data()
		}
		network_manager.sync_game_state(initial_state)
		# Host builds its own world from the generated state.
		receive_game_state(initial_state)

func _process(delta):
	if multiplayer.is_server() and world_built and game_started:
		if player_actions <= 0:
			turn_manager.start_next_turn()

# NEW RPC: Called by any player to tell the host to reduce the action count.
@rpc("any_peer")
func use_player_action():
	if not multiplayer.is_server(): return
	player_actions -= 1

# NEW RPC: Called by any player to tell the host to end the turn immediately.
@rpc("any_peer")
func end_player_turn():
	if not multiplayer.is_server(): return
	player_actions = 0

# This is called by the TurnManager to sync the current turn across all clients.
@rpc("any_peer", "call_local")
func set_current_turn_globally(player_id: int, new_round: int):
	if not world_built:
		queued_turn_id = player_id
		queued_round = new_round
		return
	
	game_started = true
	current_round = new_round
	round_label.text = "Round: %d" % current_round
	
	current_turn_player_id = player_id
	
	if spawned_players.has(player_id):
		current_player_node = spawned_players[player_id]
		player_actions = 2
		
		characters_manager.update_valid_moves(current_player_node)
		current_player_node.start_turn()
		print("--- Round %d | It is now Player %d's turn. ---" % [current_round, player_id])
	else:
		print("Error: Could not find player with ID %d to start turn." % player_id)
	
	if multiplayer.get_unique_id() != player_id:
		characters_manager.adjacents_array.clear()
		characters_manager.occupied_adjacents_array.clear()
		floors_and_tiles_manager.unhover_adjacents_floor()

func receive_game_state(state: Dictionary):
	if world_built: return # Prevent rebuilding the world
	
	print("Applying game state...")
	await floors_and_tiles_manager.build_from_data(state)
	obstacles_manager.build_from_data(state)
	world_built = true
	world_build_complete.emit()
	
	# After the world is built, ensure the players are spawned correctly
	update_player_spawns(network_manager.players)

func _on_world_build_complete():
	if queued_turn_id != -1:
		set_current_turn_globally(queued_turn_id, queued_round)
		queued_turn_id = -1
		queued_round = -1

@rpc("any_peer", "call_local")
func update_floor_occupancy(floor_id: int, player_id: int):
	if not is_instance_valid(floors_and_tiles_manager) or floor_id < 0 or floor_id >= floors_and_tiles_manager.floors_array.size():
		return

	var floor_node = floors_and_tiles_manager.floors_array[floor_id]
	if player_id == -1:
		floor_node.occupied_by_player = null
	elif spawned_players.has(player_id):
		floor_node.occupied_by_player = spawned_players[player_id]

func _on_players_changed(_players):
	if multiplayer.is_server():
		network_manager.sync_game_state(current_game_state)

func setup_and_sync_level():
	"""(HOST ONLY) Generates level data, applies it, and sends it to clients."""
	# 1. Generate all the random data.
	var obstacle_data = obstacles_manager.generate_obstacle_data()
	var tile_data = floors_and_tiles_manager.generate_random_tile_data()
	
	var game_state = {
		"obstacles": obstacle_data,
		"tiles": tile_data,
		"player_number": player_number,
		"current_level_id": current_level_id
	}
	
	# 2. Apply the data locally on the host.
	apply_level_data(game_state)
	
	# 3. Send the authoritative data to all clients.
	network_manager.sync_game_state(game_state)

func _on_game_state_received():
	"""(CLIENT ONLY) Called when the client receives the initial game state."""
	var state = network_manager.game_state
	apply_level_data(state)

func apply_level_data(data):
	"""(HOST & CLIENTS) Builds the level from the authoritative data dictionary."""
	# Set variables that might affect generation first.
	if data.has("player_number"):
		self.player_number = data.player_number
	if data.has("current_level_id"):
		self.current_level_id = data.current_level_id

	# Apply the synchronized layouts.
	if data.has("obstacles"):
		obstacles_manager.apply_obstacle_data(data.obstacles)
	if data.has("tiles"):
		floors_and_tiles_manager.apply_random_tile_data(data.tiles)

## Player
# This function should completely replace your old 'update_player_spawns' function.
func update_player_spawns(players_data: Dictionary):
	# This function ONLY runs on the host to manage all players.
	if not multiplayer.is_server():
		return

	# Check for players who disconnected and tell clients to despawn them.
	for player_id in spawned_players.keys():
		if not players_data.has(player_id):
			despawn_player_on_clients.rpc(player_id)

	# Check for new players and tell clients to spawn them.
	for player_id in players_data:
		if not spawned_players.has(player_id):
			var p_data = players_data[player_id]
			var p_num = p_data.get("player_number", -1)
			var floor_id = start_positions.get(p_num, -1)

			if floor_id != -1:
				var target_floor = floors_and_tiles_manager.floors_array[floor_id]
				var start_pos = target_floor.global_transform.origin + Vector3(0, 0.5, 0)
				spawn_player_on_clients.rpc(p_data, start_pos, floor_id)
			
	#if not turn_manager.game_started:
		#turn_manager.start_game()

@rpc("any_peer", "call_local")
func set_player_position(player_id: int, position: Vector3):
	if spawned_players.has(player_id):
		var player_node = spawned_players[player_id]
		player_node.global_transform.origin = position
		print("RPC received: Set position for player %d" % player_id)
	else:
		print("RPC warning: Could not find spawned player %d to set position." % player_id)

# This command is sent from the host to everyone to create a character.
@rpc("any_peer", "call_local")
func spawn_player_on_clients(p_data: Dictionary, position: Vector3, initial_floor_id: int):
	var player_id = p_data["id"]

	# This check prevents a character from being spawned twice on the same machine.
	if spawned_players.has(player_id):
		return
	
	print("Spawning player %s at floor %d" % [p_data["name"], initial_floor_id])
	var player_instance = player_scene.instantiate()
	player_instance.name = str(player_id)
	
	add_child(player_instance)
	spawned_players[player_id] = player_instance
	
	player_instance.set_multiplayer_authority(player_id)
	player_instance.set_display_name(p_data["name"])
	player_instance.global_transform.origin = position
	player_instance.set_initial_floor(initial_floor_id)

	# Set the initial floor occupancy on all clients
	#if initial_floor_id != -1 and initial_floor_id < floors_and_tiles_manager.floors_array.size():
		#var initial_floor_node = floors_and_tiles_manager.floors_array[initial_floor_id]
		#initial_floor_node.occupied_by_player = player_instance
	#
	#if player_id == multiplayer.get_unique_id():
		#current_player_node = player_instance

# This command is sent from the host to everyone to remove a character.
@rpc("any_peer", "call_local")
func despawn_player_on_clients(player_id: int):
	if spawned_players.has(player_id):
		var player_node = spawned_players[player_id]
		if player_node == current_player_node:
			current_player_node = null
		player_node.queue_free()
		spawned_players.erase(player_id)
