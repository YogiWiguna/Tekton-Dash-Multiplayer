extends Node

signal player_number_ready
signal power_card_active
signal choose_tile_for_activate_power_card
signal want_to_use_power_card
signal spawn_active
signal dice_rolled

# Signal for animaiton take tile
signal take_tile_animation_done

# Signal for move racer
signal first_move
signal move_player_done

# Signal for put away
signal put_away_done

# Signal for put back
signal put_back_done
signal put_back_to_floor

# Signal for swap tile
signal choose_tile_to_swap
signal swap_tile_done

# Signal for book tiles
signal book_tiles_done

signal bot_take_tile
var is_bot_take_tile := false

var back_option

var is_starter : bool = true
var current_round : int = 0

# Variable for lap 2
var is_lap_2 := false
var action_set := 0
var player_id_finish = null
var is_end_game := false

# Variable for special move 
var is_special_move_on_pb := false

# Variable for sabotage meter 
var sabotage_meter_update := false
var sabotage_count = [0,0,0,0]

var player_playing_node : Node3D

func set_player_number():
	player_number_ready.emit()


# List of possible items to spawn, For PLAYER BOARD
const item_material_list = [
	preload("res://assets/materials/player_board_and_blue_print/heart.tres"),
	preload("res://assets/materials/player_board_and_blue_print/star.tres"),
	preload("res://assets/materials/player_board_and_blue_print/coin.tres"),
	preload("res://assets/materials/player_board_and_blue_print/diamond.tres")
]

const tiles_hologram_material_list = [
	preload("res://assets/materials/player_board_and_blue_print/heart_hologram.tres"),
	preload("res://assets/materials/player_board_and_blue_print/star_hologram.tres"),
	preload("res://assets/materials/player_board_and_blue_print/coin_hologram.tres"),
	preload("res://assets/materials/player_board_and_blue_print/diamond_hologram.tres")
]

# FOR ARENA 
const tile_trans_material_list = [
	preload("res://assets/materials/tiles/heart_tile_surface_mat_trans.tres"),
	preload("res://assets/materials/tiles/star_tile_surface_mat_trans.tres"),
	preload("res://assets/materials/tiles/coin_tile_surface_mat_trans.tres"),
	preload("res://assets/materials/tiles/diamond_tile_surface_mat_trans.tres")
]

const tile_hologram_trans_material_list = [
	preload("res://assets/materials/tiles/heart_tile_holo_surface_mat_trans.tres"),
	preload("res://assets/materials/tiles/star_tile_holo_surface_mat_trans.tres"),
	preload("res://assets/materials/tiles/coin_tile_holo_surface_mat_trans.tres"),
	preload("res://assets/materials/tiles/diamond_tile_holo_surface_mat_trans.tres")
]

# List of possible items to spawn
#region List name of the taken tiles from board
const tiles_name = [
	"heart",
	"star",
	"coin",
	"diamond"
]

const tiles_hologram_name = [
	"heart_hologram",
	"star_hologram",
	"coin_hologram",
	"diamond_hologram"
]
#endregion

const tiles_surface_material = [
	"res://assets/materials/tiles/heart_tile_surface_mat.tres",
	"res://assets/materials/tiles/star_tile_surface_mat.tres",
	"res://assets/materials/tiles/coin_tile_surface_mat.tres",
	"res://assets/materials/tiles/diamond_tile_surface_mat.tres"
]

const tiles_hologram_surface_material = [
	"res://assets/materials/tiles/heart_hologram_tile_surface_mat.tres",
	"res://assets/materials/tiles/star_hologram_tile_surface_mat.tres",
	"res://assets/materials/tiles/coin_hologram_tile_surface_mat.tres",
	"res://assets/materials/tiles/diamond_hologram_tile_surface_mat.tres"
]

# Tiles Surface Material 
var coin_tile_surface_mat = load("res://assets/materials/tiles/coin_tile_surface_mat.tres")
var diamond_tile_surface_mat = load("res://assets/materials/tiles/diamond_tile_surface_mat.tres")
var heart_tile_surface_mat = load("res://assets/materials/tiles/heart_tile_surface_mat.tres")
var star_tile_surface_mat = load("res://assets/materials/tiles/star_tile_surface_mat.tres")

# Tiles Hologram Surface Material
var coin_hologram_tile_surface_mat = load("res://assets/materials/tiles/coin_hologram_tile_surface_mat.tres")
var diamond_hologram_tile_surface_mat = load("res://assets/materials/tiles/diamond_hologram_tile_surface_mat.tres")
var heart_hologram_tile_surface_mat = load("res://assets/materials/tiles/heart_hologram_tile_surface_mat.tres")
var star_hologram_tile_surface_mat = load("res://assets/materials/tiles/star_hologram_tile_surface_mat.tres")

# Tiles Trans Surface Material
var coin_tile_trans_surface_mat = load("res://assets/materials/tiles/coin_tile_surface_mat_trans.tres")
var diamond_tile_trans_surface_mat = load("res://assets/materials/tiles/diamond_tile_surface_mat_trans.tres")
var heart_tile_trans_surface_mat = load("res://assets/materials/tiles/heart_tile_surface_mat_trans.tres")
var star_tile_trans_surface_mat = load("res://assets/materials/tiles/star_tile_surface_mat_trans.tres")

# Tiles Hologram Trans Surface Material
var coin_tile_hologram_trans_surface_mat = load("res://assets/materials/tiles/coin_tile_holo_surface_mat_trans.tres")
var diamond_tile_hologram_trans_surface_mat = load("res://assets/materials/tiles/diamond_tile_holo_surface_mat_trans.tres")
var heart_tile_hologram_trans_surface_mat = load("res://assets/materials/tiles/heart_tile_holo_surface_mat_trans.tres")
var star_tile_hologram_trans_surface_mat = load("res://assets/materials/tiles/star_tile_holo_surface_mat_trans.tres")


# Variable for the tile spawn
var is_spawn_tile := false

# Variable for bot 
var is_bot_active :=  false

# Variable for action is already done
var is_action_done := false

# Variable for active power card
var is_power_card_active := false

# Variable for power card (plus action)
var is_plus_action

# Variable for Power Card Move Stack
var available_floors_for_move_stack : Array = []

# Variable for Power Card Move Tile Spawn
var available_floors_for_move_tile_spawn : Array = []
var tiles_spawns_resource_name := [
	"coin_tile_spawn",
	"diamond_tile_spawn", 
	"heart_tile_spawn",
	"star_tile_spawn",
	"coin_and_heart_tile_spawn",
	"diamond_and_star_tile_spawn"
]

# Varibale for Power Card Move Block
var available_floors_for_move_block : Array = []
var block_spawns_resource_name := [
	"block_1",
	"block_2"
]

var available_floors_for_move_boost: Array = []
var boost_spawns_resource_name := [
	"boost_down",
	"boost_left",
	"boost_right",
	"boost_up",
	"boost_special_1",
	"boost_special_2"
]


# ========================================
# ===              Arena               ===
# ========================================
var arena_id: int = 0
var player_ids: Dictionary = {
	"player_0": 0,
	"player_1": 1,
	"player_2": 2,
	"player_3": 3
}

var tekton_ids: Dictionary = {
	"player_0": 0,
	"player_1": 1,
	"player_2": 2,
	"player_3": 3
}

var personality_ids : Dictionary = {
	0: 
		{
		"lap_1" : -1,
		"lap_2" : -1,
		},
	1: 
		{
		"lap_1" : -1,
		"lap_2" : -1,
		},
	2: 
		{
		"lap_1" : -1,
		"lap_2" : -1,
		},
	3: 
		{
		"lap_1" : -1,
		"lap_2" : -1,
		}
}

var personality_count : int = 0

func reset_lap_values():
	for key in personality_ids.keys():
		personality_ids[key]["lap_1"] = -1
		personality_ids[key]["lap_2"] = -1

func reset_game_variables():
	# Reset boolean flags
	is_starter = true
	current_round = 0
	is_lap_2 = false
	action_set = 0
	player_id_finish = null
	is_end_game = false
	is_special_move_on_pb = false
	sabotage_meter_update = false
	is_spawn_tile = false
	is_bot_active = false
	is_action_done = false
	is_power_card_active = false
	
	# Reset arrays
	sabotage_count = [0, 0, 0, 0]
	available_floors_for_move_stack = []
	available_floors_for_move_tile_spawn = []
	available_floors_for_move_block = []
	available_floors_for_move_boost = []

	
	# Reset personality lap values
	reset_lap_values()
	
	# Reset personality count
	personality_count = 0
	
	# Reset other references if needed
	player_playing_node = null
	back_option = null


func set_arena_id(id: int) -> void:
	arena_id = id

func get_arena_id() -> int:
	return arena_id

func set_player_ids(ids: Dictionary) -> void:
	player_ids = ids

func get_player_ids() -> Dictionary:
	return player_ids


func set_bot_target_position(player_number, current_player_floor_id: int, target_movement_id: int, char_pos, _target):
	print("target movement id : ", target_movement_id)
	if player_number == 4:
		match current_player_floor_id:
			0,1,2,3:
				if target_movement_id == current_player_floor_id + player_number:
					_target = Vector3i(char_pos.x + 1, 0, char_pos.z)
			4,8,12,16,20,24,28,32:
				if target_movement_id == current_player_floor_id + 5:
					_target = Vector3i(char_pos.x + 1, 0, char_pos.z + 1)
				elif target_movement_id == current_player_floor_id + player_number:
					_target = Vector3i(char_pos.x + 1, 0, char_pos.z)
				elif target_movement_id == current_player_floor_id + 1:
					_target = Vector3i(char_pos.x, 0, char_pos.z + 1)
				elif target_movement_id == current_player_floor_id - 3:
					_target = Vector3i(char_pos.x - 1, 0, char_pos.z + 1)
				elif target_movement_id == current_player_floor_id - player_number:
					_target = Vector3i(char_pos.x - 1, 0, char_pos.z)
			5,6,9,10,13,14,17,18,21,22,25,26,29,30,33,34:
				if target_movement_id == current_player_floor_id + 5:
					_target = Vector3i(char_pos.x + 1, 0, char_pos.z + 1)
				elif target_movement_id == current_player_floor_id + player_number:
					_target = Vector3i(char_pos.x + 1, 0, char_pos.z)
				elif target_movement_id == current_player_floor_id + 3:
					_target = Vector3i(char_pos.x + 1, 0, char_pos.z - 1)
				elif target_movement_id == current_player_floor_id + 1:
					_target = Vector3i(char_pos.x, 0, char_pos.z + 1)
				elif target_movement_id == current_player_floor_id - 1:
					_target = Vector3i(char_pos.x, 0, char_pos.z - 1)
				elif target_movement_id == current_player_floor_id - 3:
					_target = Vector3i(char_pos.x - 1, 0, char_pos.z + 1)
				elif target_movement_id == current_player_floor_id - player_number:
					_target = Vector3i(char_pos.x - 1, 0, char_pos.z)
				elif target_movement_id == current_player_floor_id - 5:
					_target = Vector3i(char_pos.x - 1, 0, char_pos.z - 1)
			7,11,15,19,23,27,31,35:
				if target_movement_id == current_player_floor_id + player_number:
					_target = Vector3i(char_pos.x + 1, 0, char_pos.z)
				elif target_movement_id == current_player_floor_id + 3:
					_target = Vector3i(char_pos.x + 1, 0, char_pos.z - 1)
				elif target_movement_id == current_player_floor_id - 1:
					_target = Vector3i(char_pos.x, 0, char_pos.z - 1)
				elif target_movement_id == current_player_floor_id - player_number:
					_target = Vector3i(char_pos.x - 1, 0, char_pos.z)
				elif target_movement_id == current_player_floor_id - 5:
					_target = Vector3i(char_pos.x - 1, 0, char_pos.z - 1)
			#36,37,38,39:  # Add special handling for finish line positions
				#if target_movement_id == current_player_floor_id - player_number:  # Moving back
					#_target = Vector3i(char_pos.x - 1, 0, char_pos.z)
				#elif target_movement_id == current_player_floor_id - 5:  # Moving back diagonally
					#_target = Vector3i(char_pos.x - 1, 0, char_pos.z - 1)
				#elif target_movement_id == current_player_floor_id - 3:  # Moving back diagonally
					#_target = Vector3i(char_pos.x - 1, 0, char_pos.z + 1)
				#elif target_movement_id == current_player_floor_id - 1:  # Moving left
					#_target = Vector3i(char_pos.x, 0, char_pos.z - 1)
				#elif target_movement_id == current_player_floor_id + 1:  # Moving right
					#_target = Vector3i(char_pos.x, 0, char_pos.z + 1)
			_:
				_target = Vector3i(0,0,0)
	return _target
