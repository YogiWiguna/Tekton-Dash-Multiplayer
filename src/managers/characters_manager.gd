# file: src/managers/characters_manager.gd
extends Node3D
class_name CharactersManager

# Preload the new resource script
const PlayerMovementData = preload("res://src/player/player_movement.gd")

@onready var main = get_node("/root/Main")
@onready var floors_and_tiles_manager = get_node("/root/Main/FloorsAndTileManager")
@onready var obstacles_manager = get_node("/root/Main/Obstacles")

var adjacents_array: Array = []
var occupied_adjacents_array: Array = []

# Create an instance of the movement calculator
var _movement_calculator = PlayerMovementData.new()

# This function will now use your script to get the valid moves
func update_valid_moves(player_node):
	if not is_instance_valid(player_node):
		return

	# Call the function from your PlayerMovement script
	adjacents_array = _movement_calculator.check_adjacents_floors(
		player_node.current_player_floor_id,
		main.player_number,
		floors_and_tiles_manager.floors_array,
		obstacles_manager,
		main.current_level_id
	)
	
	# Your script also calculates occupied tiles, so we'll grab that result too
	occupied_adjacents_array = _movement_calculator.occupied_arr

	# Now that the arrays are updated, refresh the tile highlighters
	floors_and_tiles_manager.unhover_adjacents_floor()
	floors_and_tiles_manager.hover_adjacents_floor()
