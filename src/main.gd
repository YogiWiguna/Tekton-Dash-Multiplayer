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

var current_player_node

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
	
	# Spawn and position the player after the world is ready
	setup_player_start_position()

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
func setup_player_start_position():
	# Only create a new player if one doesn't already exist
	if not is_instance_valid(current_player_node):
		if player_scene:
			current_player_node = player_scene.instantiate()
			add_child(current_player_node)
		else:
			print("Player scene is not set in the inspector!")
			return

	# Set the target floor ID. Arrays are 0-indexed, so floor_1 is at index 1.
	var target_floor_id = 1

	# Make sure the floors have been created and the ID is valid
	if not floors_and_tiles_manager.floors_array.is_empty() and target_floor_id < floors_and_tiles_manager.floors_array.size():
		# Get the target floor node from the manager
		var target_floor = floors_and_tiles_manager.floors_array[target_floor_id]
		var start_position = target_floor.global_transform.origin

		# Set the player's position. You might want a small Y-offset to make sure it's standing on top.
		current_player_node.global_transform.origin = start_position + Vector3(0, 0.5, 0)
		print("Player has been positioned at the center of floor_", target_floor_id)
	else:
		print("Error: Could not find floor with ID: ", target_floor_id, " to position player.")
