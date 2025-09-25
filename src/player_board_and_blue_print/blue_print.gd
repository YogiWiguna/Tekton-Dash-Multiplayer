extends Control

# Preload the slot scene
var slot_scene = preload("res://scenes/player_board_and_blue_print/blue_print_slot.tscn")


@onready var blue_print_grid = $blue_print_grid

# Blue Print size 
const slots : int = 9
const row : int = 3

var blue_print :=  []
var blue_print_inventory_array := []

const item_list = [
	preload("res://assets/materials/player_board_and_blue_print/heart.tres"),
	preload("res://assets/materials/player_board_and_blue_print/star.tres"),
	preload("res://assets/materials/player_board_and_blue_print/coin.tres"),
	preload("res://assets/materials/player_board_and_blue_print/diamond.tres")
]

# Called when the node enters the scene tree for the first time.
func _ready():
	create_blue_print_inventory()
	# 6 items
	#var _random_id = generate_random_id_array(9, 0, 3, 1.0)
	#print("random : ", _random_id)
	#set_item_tile_into_blue_print(_random_id)
	#set_item_tile_into_slot()

	# Full items
	#var _full_id_array = generate_random_full_id_mission_array(9, 0, 3)
	#print("full id array : ", full_id_array)
	#set_item_on_blue_print(blue_print)

func create_blue_print_inventory():
	for i in range(slots):
		var _slot = slot_scene.instantiate()
		blue_print_grid.add_child(_slot,true)
		blue_print.append(null)
		blue_print_inventory_array.append(_slot)


#func generate_blue_print():
	#var _random_id = generate_random_id_array(9, 0, 3, 1.0)
	#set_item_tile_into_blue_print(_random_id)


# Generate random id 
#func generate_random_id_array(_size: int, min_value: int, max_value: int, null_probability: float) -> Array:
	#var rng = RandomNumberGenerator.new()
	#rng.randomize()
	#var result = []
	#var null_count = 0
	## Change max null for null show on the blue print
	#var max_nulls = 3
	#for i in range(_size):
		#if null_count < max_nulls and rng.randf() < null_probability:
			#result.append(null)
			#null_count += 1
		#else:
			#result.append(rng.randi_range(min_value, max_value))
	## Shuffle the array to randomize the position of null values
	#result.shuffle()  
	#return result

# Generate full blue_print 
#func generate_random_full_id_mission_array(_size: int, min_value: int, max_value: int) -> Array:
	#var rng = RandomNumberGenerator.new()
	#rng.randomize()
	#var result = []
	#for i in range(_size):
		#result.append(rng.randi_range(min_value, max_value))
	#
	## Shuffle the array to randomize the position of values
	#result.shuffle()
	#
	#return result

# Set item into blue_print_array
#func set_item_tile_into_blue_print(_random_id):
	#for _id in range(blue_print.size()):
		#if _random_id[_id] == null :
			#blue_print[_id] = null
		#else:
			#blue_print[_id] = item_list[_random_id[_id]]
	#return blue_print

# Set item from blue_print_array into the slot
func set_item_tile_into_slot():
	for _id in range(blue_print.size()):
		blue_print_inventory_array[_id].item = blue_print[_id]
