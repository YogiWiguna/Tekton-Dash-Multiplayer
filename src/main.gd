extends Node3D

@export var current_level_id : int = 1 

# Variables for size of arena
var player_number : int = 4 # Default for player number is 4
var default_rows : int = 10 # Default for rows is 10

# Variable for player actions
var player_actions : int = 2 

@onready var network_manager = get_node("/root/NetworkManager")
@onready var floors_and_tiles_manager = $FloorsAndTileManager
@onready var obstacles_manager = $Obstacles

var current_game_state = {}

func _ready():
	# Connect to the signal that fires when a client receives the game state
	network_manager.game_state_received.connect(receive_game_state)
	
	# The HOST is the authority and generates the game world
	if multiplayer.is_server():
		# Wait a frame to ensure all nodes are ready before generating the level
		await get_tree().process_frame
		
		# First, generate the initial state data dictionary
		var initial_state = {
			"player_number": player_number,
			"default_rows": default_rows,
			# The managers will generate their respective data without building nodes yet
			"tiles": floors_and_tiles_manager.generate_random_tile_data(),
			"obstacles": obstacles_manager.generate_obstacle_data()
		}
		
		# Now, the HOST builds its own world using this authoritative state.
		# This ensures the host builds the level only ONCE.
		receive_game_state(initial_state)
		
		# Finally, the HOST sends this state to all current and future clients.
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
		
	# Set variables from the host
	player_number = state.get("player_number", 4)
	default_rows = state.get("default_rows", 10)
	
	# Use the received data to build the level
	await floors_and_tiles_manager.build_from_data(state)
	obstacles_manager.build_from_data(state)

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
