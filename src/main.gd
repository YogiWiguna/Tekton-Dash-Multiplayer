extends Node3D

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

var current_game_state = {}
var spawned_players = {}

var current_player_node = null

var start_positions = { 1: 1, 2: 2, 3: 0, 4: 3 }

var world_built = false

func _ready():
	network_manager.game_state_received.connect(receive_game_state)
	network_manager.players_changed.connect(update_player_spawns)
	
	if multiplayer.is_server():
		var initial_state = {
			"player_number": player_number,
			"default_rows": default_rows,
			"tiles": floors_and_tiles_manager.generate_random_tile_data(),
			"obstacles": obstacles_manager.generate_obstacle_data()
		}
		network_manager.sync_game_state(initial_state)
		# Host builds its own world immediately
		receive_game_state(initial_state)


@rpc("any_peer", "call_local")
func update_floor_occupancy(floor_id: int, player_id: int):
	# Safety check to ensure the floor and manager exist
	if not is_instance_valid(floors_and_tiles_manager) or floor_id < 0 or floor_id >= floors_and_tiles_manager.floors_array.size():
		return

	var floor_node = floors_and_tiles_manager.floors_array[floor_id]
	
	# -1 is used to signal that the player has left the floor
	if player_id == -1:
		floor_node.occupied_by_player = null
	elif spawned_players.has(player_id):
		# Assign the player node to the floor's occupied_by_player variable
		floor_node.occupied_by_player = spawned_players[player_id]
	else:
		# If the player ID is not found, set to null as a fallback
		floor_node.occupied_by_player = null

func _on_players_changed(_players):
	if multiplayer.is_server():
		# A player connected or disconnected.
		# Send the latest game state to ensure everyone is synced,
		# which is especially important for late joiners.
		network_manager.sync_game_state(current_game_state)

func receive_game_state(state: Dictionary):
	if world_built: return # Prevent rebuilding the world
	
	print("Applying game state...")
	await floors_and_tiles_manager.build_from_data(state)
	obstacles_manager.build_from_data(state)
	world_built = true
	
	# After the world is built, ensure the players are spawned correctly
	update_player_spawns(network_manager.players)

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
			var player_number = p_data.get("player_number", -1)
			var target_floor_id = start_positions.get(player_number, -1)

			if target_floor_id != -1 and target_floor_id < floors_and_tiles_manager.floors_array.size():
				var target_floor = floors_and_tiles_manager.floors_array[target_floor_id]
				var start_pos = target_floor.global_transform.origin + Vector3(0, 0.5, 0)
				
				# Send the command to everyone to spawn this player at the correct position and floor.
				spawn_player_on_clients.rpc(p_data, start_pos, target_floor_id)
			else:
				print("Server Error: Could not find a valid start position for player number %d" % player_number)

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
	if initial_floor_id != -1 and initial_floor_id < floors_and_tiles_manager.floors_array.size():
		var initial_floor_node = floors_and_tiles_manager.floors_array[initial_floor_id]
		initial_floor_node.occupied_by_player = player_instance
	
	if player_id == multiplayer.get_unique_id():
		current_player_node = player_instance

# This command is sent from the host to everyone to remove a character.
@rpc("any_peer", "call_local")
func despawn_player_on_clients(player_id: int):
	if spawned_players.has(player_id):
		var player_node = spawned_players[player_id]
		if player_node == current_player_node:
			current_player_node = null
		player_node.queue_free()
		spawned_players.erase(player_id)
