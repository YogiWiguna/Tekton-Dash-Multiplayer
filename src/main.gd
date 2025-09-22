extends Node3D

@export var current_level_id : int = 1 
@export var player_scene: PackedScene = preload("res://scenes/player/player_0.tscn")

# Variables for size of arena
var player_number : int = 4 # Default for player number is 4
var default_rows : int = 10 # Default for rows is 10

# Variable for player actions
var player_actions : int = 2 

@onready var network_manager = get_node("/root/NetworkManager")
@onready var floors_and_tiles_manager = $FloorsAndTileManager
@onready var obstacles_manager = $Obstacles

var current_game_state = {}
var spawned_players = {}

var current_player_node

var start_positions = {
	1: 1,  # Player 1 (Host) starts on floor_1
	2: 2,  # Player 2 starts on floor_2
	3: 0,  # Player 3 starts on floor_0
	4: 3   # Player 4 starts on floor_3
}

func _ready():
	network_manager.game_state_received.connect(receive_game_state)
	# Connect to the signal that tells us when players join or leave
	network_manager.players_changed.connect(update_player_spawns)
	
	if multiplayer.is_server():
		await get_tree().process_frame
		
		var initial_state = {
			"player_number": player_number,
			"default_rows": default_rows,
			"tiles": floors_and_tiles_manager.generate_random_tile_data(),
			"obstacles": obstacles_manager.generate_obstacle_data()
		}
		
		receive_game_state(initial_state)
		network_manager.sync_game_state(initial_state)


func _on_players_changed(_players):
	if multiplayer.is_server():
		# A player connected or disconnected.
		# Send the latest game state to ensure everyone is synced,
		# which is especially important for late joiners.
		network_manager.sync_game_state(current_game_state)

func receive_game_state(state: Dictionary):
	print("Applying game state...")
	if state.is_empty():
		print("Received empty game state, skipping build.")
		return
		
	player_number = state.get("player_number", 4)
	default_rows = state.get("default_rows", 10)
	
	await floors_and_tiles_manager.build_from_data(state)
	obstacles_manager.build_from_data(state)
	
	# After building the world, we need to spawn players based on the current list
	update_player_spawns(spawned_players)

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
	# 1. Remove players who have disconnected
	var current_spawned_ids = spawned_players.keys()
	for player_id in current_spawned_ids:
		if not players_data.has(player_id):
			print("Player %d is no longer in the list. Removing." % player_id)
			var player_node_to_remove = spawned_players[player_id]

			if player_node_to_remove == current_player_node:
				current_player_node = null

			if is_instance_valid(player_node_to_remove):
				player_node_to_remove.queue_free()
			spawned_players.erase(player_id)

	# 2. Spawn players who are new
	for player_id in players_data:
		if not spawned_players.has(player_id):
			print("Player %d is new. Spawning." % player_id)
			var p_data = players_data[player_id]
			
			var player_instance = player_scene.instantiate()
			player_instance.name = str(player_id)
			
			add_child(player_instance)
			
			player_instance.set_display_name(p_data.name)
			
			spawned_players[player_id] = player_instance

			player_instance.set_multiplayer_authority(player_id)

			if player_id == multiplayer.get_unique_id():
				current_player_node = player_instance
			
			var target_floor_id = start_positions.get(player_id, player_id)

			if target_floor_id < floors_and_tiles_manager.floors_array.size():
				var target_floor = floors_and_tiles_manager.floors_array[target_floor_id]
				var start_pos = target_floor.global_transform.origin + Vector3(0, 0.5, 0)
				player_instance.global_transform.origin = start_pos
			else:
				print("Error: Invalid floor ID %d for player %d" % [target_floor_id, player_id])
