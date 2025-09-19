extends Node3D
class_name Obstacles

@onready var map = $".."
@onready var characters_regions = $"../CharactersManager"
@onready var floors_and_tiles_regions = $"../FloorsAndTileManager"
@onready var camera_3d = $"../camera_3d"

# Tiles Spawn Material
var coin_tile_spawn_surface_mat = load("res://assets/materials/obstacles/tiles_spawn/coin_tile_spawn_surface_mat.tres")
var diamond_tile_spawn_surface_mat = load("res://assets/materials/obstacles/tiles_spawn/diamond_tile_spawn_surface_mat.tres")
var heart_tile_spawn_surface_mat = load("res://assets/materials/obstacles/tiles_spawn/heart_tile_spawn_surface_mat.tres")
var star_tile_spawn_surface_mat = load("res://assets/materials/obstacles/tiles_spawn/star_tile_spawn_surface_mat.tres")
var coin_and_heart_tile_spawn_surface_mat = load("res://assets/materials/obstacles/tiles_spawn/coin_and_heart_tile_spawn_surface_mat.tres")
var diamond_and_star_tile_spawn_surface_mat = load("res://assets/materials/obstacles/tiles_spawn/diamond_and_star_tile_spawn_surface_mat.tres")

# Stacks Material
var stack_surface_mat = load("res://assets/materials/obstacles/stack/stack_surface_mat.tres")
var stack_special_surface_mat = load("res://assets/materials/obstacles/stack/stack_special_surface_mat.tres")

# Boosts Material
var boost_up_surface_mat = load("res://assets/materials/obstacles/boosts/boost_up.tres")
var boost_down_surface_mat = load("res://assets/materials/obstacles/boosts/boost_down.tres")
var boost_right_surface_mat = load("res://assets/materials/obstacles/boosts/boost_right.tres")
var boost_left_surface_mat = load("res://assets/materials/obstacles/boosts/boost_left.tres")
var boost_special_1_surface_mat = load("res://assets/materials/obstacles/boosts/boost_special_1.tres")
var boost_special_2_surface_mat = load("res://assets/materials/obstacles/boosts/boost_special_2.tres")

# Blocks Material
var block_1_material_surface_mat = load("res://assets/materials/obstacles/blocks/block_1.tres")
var block_2_material_surface_mat = load("res://assets/materials/obstacles/blocks/block_2.tres")
var block_3_material_surface_mat = load("res://assets/materials/obstacles/blocks/block_3.tres")

# Stack Texture 
const stack_special_water_texture = preload("res://assets/graphics/obstacles/water_arena/stack_special_water.png")
const stack_water_texture = preload("res://assets/graphics/obstacles/water_arena/stack_water.png")

const stack_bridge_texture = preload("res://assets/graphics/obstacles/bridge_arena/stack_bridge.png")
const stack_special_bridge_texture = preload("res://assets/graphics/obstacles/bridge_arena/stack_special_bridge.png")

const stack_farm_texture = preload("res://assets/graphics/obstacles/farm_arena/stack_farm.png")
const stack_special_farm_texture = preload("res://assets/graphics/obstacles/farm_arena/stack_special_farm.png")

const stack_forest_texture = preload("res://assets/graphics/obstacles/forest_arena/stack_forest.png")
const stack_special_forest_texture = preload("res://assets/graphics/obstacles/forest_arena/stack_special_forest.png")

const stack_mine_texture = preload("res://assets/graphics/obstacles/mine_arena/stack_mine.png")
const stack_special_mine_texture = preload("res://assets/graphics/obstacles/mine_arena/stack_special_mine.png")

## Boost Texture
# Water
const boost_special_1_water_texture = preload("res://assets/graphics/obstacles/water_arena/boost_special_1_water.png")
const boost_special_2_water_texture = preload("res://assets/graphics/obstacles/water_arena/boost_special_2_water.png")
const boost_water_right_texture = preload("res://assets/graphics/obstacles/water_arena/boost_water_right.png")
const boost_water_left_texture = preload("res://assets/graphics/obstacles/water_arena/boost_water_left.png")
const boost_water_down_texture = preload("res://assets/graphics/obstacles/water_arena/boost_water_down.png")
const boost_water_up_texture = preload("res://assets/graphics/obstacles/water_arena/boost_water_up.png")

# Bridge
const boost_bridge_down_texture = preload("res://assets/graphics/obstacles/bridge_arena/boost_bridge_down.png")
const boost_bridge_left_texture = preload("res://assets/graphics/obstacles/bridge_arena/boost_bridge_left.png")
const boost_bridge_right_texture = preload("res://assets/graphics/obstacles/bridge_arena/boost_bridge_right.png")
const boost_bridge_up_texture = preload("res://assets/graphics/obstacles/bridge_arena/boost_bridge_up.png")
const boost_special_1_bridge_texture = preload("res://assets/graphics/obstacles/bridge_arena/boost_special_1_bridge.png")
const boost_special_2_bridge_texture = preload("res://assets/graphics/obstacles/bridge_arena/boost_special_2_bridge.png")

# Farm
const boost_farm_down_texture = preload("res://assets/graphics/obstacles/farm_arena/boost_farm_down.png")
const boost_farm_left_texture = preload("res://assets/graphics/obstacles/farm_arena/boost_farm_left.png")
const boost_farm_right_texture = preload("res://assets/graphics/obstacles/farm_arena/boost_farm_right.png")
const boost_farm_up_texture = preload("res://assets/graphics/obstacles/farm_arena/boost_farm_up.png")
const boost_special_1_farm_texture = preload("res://assets/graphics/obstacles/farm_arena/boost_special_1_farm.png")
const boost_special_2_farm_texture = preload("res://assets/graphics/obstacles/farm_arena/boost_special_2_farm.png")

# Forest
const boost_forest_down_texture = preload("res://assets/graphics/obstacles/forest_arena/boost_forest_down.png")
const boost_forest_left_texture = preload("res://assets/graphics/obstacles/forest_arena/boost_forest_left.png")
const boost_forest_right_texture = preload("res://assets/graphics/obstacles/forest_arena/boost_forest_right.png")
const boost_forest_up_texture = preload("res://assets/graphics/obstacles/forest_arena/boost_forest_up.png")
const boost_special_1_forest_texture = preload("res://assets/graphics/obstacles/forest_arena/boost_special_1_forest.png")
const boost_special_2_forest_texture = preload("res://assets/graphics/obstacles/forest_arena/boost_special_2_forest.png")

# Mine
const boost_mine_down_texture = preload("res://assets/graphics/obstacles/mine_arena/boost_mine_down.png")
const boost_mine_left_texture = preload("res://assets/graphics/obstacles/mine_arena/boost_mine_left.png")
const boost_mine_right_texture = preload("res://assets/graphics/obstacles/mine_arena/boost_mine_right.png")
const boost_mine_up_texture = preload("res://assets/graphics/obstacles/mine_arena/boost_mine_up.png")
const boost_special_1_mine_texture = preload("res://assets/graphics/obstacles/mine_arena/boost_special_1_mine.png")
const boost_special_2_mine_texture = preload("res://assets/graphics/obstacles/mine_arena/boost_special_2_mine.png")

# Variable for tiles spawn
var tiles_spawn_id_array : Array = []
var tiles_spawn_special_id_array : Array = []

# Variable for stacks spawn
var stacks_id_array: Array = []
var stacks_special_id_array: Array = []

# Variable for boost spawn 
var boosts_id_array: Array = []
var boosts_special_id_array: Array = []

# Variable for block spawn
var blocks_id_array: Array = []
var blocks_special_id_array: Array = []


var min_id_for_spawn_obstacles: int = 12
var max_id_for_spawn_obstacles: int = 35


func _ready():
	await Global.player_number_ready
	
	set_obstacle_tile_texture()
	
	set_min_max_ids_for_obstacles_spawn()
	#print("stack id array : ", stacks_id_array)
	#print("tile spawn specials : ", tiles_spawn_special_id_array)


# Set texture obstacle based on the level arena
func set_obstacle_tile_texture():
	var current_level_id = map.current_level_id
	
	if current_level_id == 0: # Level Bridge
		stack_surface_mat.albedo_texture = stack_bridge_texture
		stack_special_surface_mat.albedo_texture = stack_special_bridge_texture
		
		boost_up_surface_mat.albedo_texture =  boost_bridge_right_texture
		boost_down_surface_mat.albedo_texture = boost_bridge_left_texture
		boost_left_surface_mat.albedo_texture = boost_bridge_up_texture
		boost_right_surface_mat.albedo_texture =  boost_bridge_down_texture
		boost_special_1_surface_mat.albedo_texture = boost_special_2_bridge_texture
		boost_special_2_surface_mat.albedo_texture =  boost_special_1_bridge_texture
	elif current_level_id == 1: # Level Farm
		stack_surface_mat.albedo_texture = stack_farm_texture
		stack_special_surface_mat.albedo_texture = stack_special_farm_texture
		
		boost_up_surface_mat.albedo_texture = boost_farm_right_texture
		boost_down_surface_mat.albedo_texture = boost_farm_left_texture
		boost_left_surface_mat.albedo_texture = boost_farm_up_texture
		boost_right_surface_mat.albedo_texture = boost_farm_down_texture
		boost_special_1_surface_mat.albedo_texture = boost_special_2_farm_texture
		boost_special_2_surface_mat.albedo_texture = boost_special_1_farm_texture
	elif current_level_id == 2: # Level Forest
		stack_surface_mat.albedo_texture = stack_forest_texture
		stack_special_surface_mat.albedo_texture = stack_special_forest_texture
		
		boost_up_surface_mat.albedo_texture = boost_forest_right_texture
		boost_down_surface_mat.albedo_texture = boost_forest_left_texture
		boost_left_surface_mat.albedo_texture = boost_forest_up_texture
		boost_right_surface_mat.albedo_texture = boost_forest_down_texture
		boost_special_1_surface_mat.albedo_texture = boost_special_2_forest_texture
		boost_special_2_surface_mat.albedo_texture = boost_special_1_forest_texture
	elif current_level_id == 3: # Level Mine
		stack_surface_mat.albedo_texture = stack_mine_texture
		stack_special_surface_mat.albedo_texture = stack_special_mine_texture
		
		boost_up_surface_mat.albedo_texture =  boost_mine_right_texture
		boost_down_surface_mat.albedo_texture =  boost_mine_left_texture
		boost_left_surface_mat.albedo_texture =  boost_mine_up_texture
		boost_right_surface_mat.albedo_texture =  boost_mine_down_texture
		boost_special_1_surface_mat.albedo_texture = boost_special_2_mine_texture
		boost_special_2_surface_mat.albedo_texture =  boost_special_1_mine_texture
	elif current_level_id == 4: # Level Water
		
		stack_surface_mat.albedo_texture = stack_water_texture
		stack_special_surface_mat.albedo_texture = stack_special_water_texture
		
		boost_up_surface_mat.albedo_texture = boost_water_right_texture
		boost_down_surface_mat.albedo_texture = boost_water_left_texture
		boost_left_surface_mat.albedo_texture = boost_water_up_texture
		boost_right_surface_mat.albedo_texture = boost_water_down_texture
		boost_special_1_surface_mat.albedo_texture = boost_special_1_water_texture
		boost_special_2_surface_mat.albedo_texture = boost_special_2_water_texture


# ========================================
# ===        Spawn The Obstacles       ===
# ========================================
func set_min_max_ids_for_obstacles_spawn():
	match map.player_number:
		3:
			min_id_for_spawn_obstacles = 9
			max_id_for_spawn_obstacles = 26
			
			set_generate_ids_for_obstacles(0)
			## Set Surface Tile Spawn
			set_tiles_spawn_material_into_obstacle_tile()
			## Set Surface Stacks
			set_stack_material_into_obstacle_tile()
			## Set Surface Boosts
			set_boost_material_into_obstacle_tile()
			## Set Surface Blocks
			set_block_material_into_block_obstacle()
		4:
			min_id_for_spawn_obstacles = 12
			max_id_for_spawn_obstacles = 35
			
			set_generate_ids_for_obstacles(0)
			#boosts_id_array = [-1,-1,-1,-1]
			#blocks_id_array = [14,22,19,35]
			
			#boosts_id_array = [7,15,21,34]
			#blocks_id_array = [14,22,19,35]
			
			#boosts_id_array = [14,19,16,24]
			#blocks_id_array = [13,15,19,21]
			
			#stacks_id_array = [8,11]
			#tiles_spawn_id_array =  [9,10,12,15]
			## Set Surface Tile Spawn
			set_tiles_spawn_material_into_obstacle_tile()
			## Set Surface Stacks
			set_stack_material_into_obstacle_tile()
			## Set Surface Boosts
			set_boost_material_into_obstacle_tile()
			## Set Surface Blocks
			set_block_material_into_block_obstacle()
		5:
			min_id_for_spawn_obstacles = 15
			max_id_for_spawn_obstacles = 44
			
			set_generate_ids_for_obstacles(1)
			# Set Surface Tile Spawn
			set_tiles_spawn_material_into_obstacle_tile()
			set_tiles_spawn_special_material_into_obstacle_tile()
			#
			# Set Surface Stacks
			set_stack_material_into_obstacle_tile()
			set_stack_special_material_into_obstacle_tile()
			#
			# Set Surface Boosts
			set_boost_material_into_obstacle_tile()
			set_boost_special_material_into_obstacle_tile()
			#
			# Set Surface Blocks
			set_block_material_into_block_obstacle()
			set_block_special_material_into_block_obstacle()
		6:
			min_id_for_spawn_obstacles = 18
			max_id_for_spawn_obstacles = 53
			
			set_generate_ids_for_obstacles(2)
			# Set Surface Tile Spawn
			set_tiles_spawn_material_into_obstacle_tile()
			set_tiles_spawn_special_material_into_obstacle_tile()
			#
			# Set Surface Stacks
			set_stack_material_into_obstacle_tile()
			set_stack_special_material_into_obstacle_tile()
			#
			# Set Surface Boosts
			set_boost_material_into_obstacle_tile()
			set_boost_special_material_into_obstacle_tile()
			#
			# Set Surface Blocks
			set_block_material_into_block_obstacle()
			set_block_special_material_into_block_obstacle()

func set_generate_ids_for_obstacles(_special_id_count):
	## Tiles Spawn
	var combine_obstacle_id

	
	tiles_spawn_id_array = generate_random_ids(min_id_for_spawn_obstacles, max_id_for_spawn_obstacles, 4,)
	#print("tiles spawn before : ", tiles_spawn_id_array)
	tiles_spawn_special_id_array = generate_random_ids(min_id_for_spawn_obstacles, max_id_for_spawn_obstacles, _special_id_count, tiles_spawn_id_array)
	combine_obstacle_id = tiles_spawn_id_array + tiles_spawn_special_id_array
	#print("tiles spawn specials : ", tiles_spawn_special_id_array)
	#print("combine obstacle ids : ", combine_obstacle_id)
	## Stack 
	stacks_id_array = generate_random_ids(min_id_for_spawn_obstacles, max_id_for_spawn_obstacles, 4, combine_obstacle_id)
	combine_obstacle_id += stacks_id_array
	stacks_special_id_array = generate_random_ids(min_id_for_spawn_obstacles, max_id_for_spawn_obstacles, _special_id_count, combine_obstacle_id)
	#print("Stacks IDs: ", stacks_id_array)
	#print("stack specials id : ", stacks_special_id_array)
	#print("combine obstacle ids : ", combine_obstacle_id)
	## Boosts 
	combine_obstacle_id += stacks_special_id_array
	boosts_id_array = generate_random_ids(min_id_for_spawn_obstacles, max_id_for_spawn_obstacles, 4, combine_obstacle_id, "boost")
	combine_obstacle_id += boosts_id_array
	boosts_special_id_array = generate_random_ids(min_id_for_spawn_obstacles, max_id_for_spawn_obstacles, _special_id_count, combine_obstacle_id, "boost_special")
	#print("boost IDs: ", boosts_id_array)
	#print("boost specials id : ", boosts_special_id_array)
	#print("combine obstacle ids : ", combine_obstacle_id)
	## Block
	blocks_id_array = generate_random_ids(min_id_for_spawn_obstacles, max_id_for_spawn_obstacles, 4, [], "block")
	blocks_special_id_array = generate_random_ids(min_id_for_spawn_obstacles, max_id_for_spawn_obstacles, _special_id_count, [], "block_special")
	#print("blocks id array : ",blocks_id_array)
	#print("blocks special id array : ", blocks_special_id_array)
	#print("combine obstacle ids : ", combine_obstacle_id)


# ========================================
# ===      Generate Ids Obstacles      ===
# ========================================
func get_adjacents(id: int) -> Array:
	return [
		id - map.player_number,  # top
		id - 1,                  # left
		id + 1,                  # right
		id + map.player_number   # bottom
	]

func is_adjacent_to_existing(id: int, existing_array: Array) -> bool:
	for existing_id in existing_array:
		if id in get_adjacents(existing_id):
			return true
	return false

func is_valid_horizontal_block(id: int, existing_horizontal_1: int, existing_horizontal_2: int, existing_vertical_1: int, existing_vertical_2: int, block_string: String) -> bool:
	var invalid_positions = []
	
	if block_string in ["block_horizontal_2", "block_horizontal_special"]:
		invalid_positions.append_array([
			existing_horizontal_1,
			existing_horizontal_1 - map.player_number,
			existing_horizontal_1 + map.player_number
		])
		invalid_positions.append_array(range(existing_horizontal_1 - 3, existing_horizontal_1 + 4))
	
	if block_string == "block_horizontal_special":
		invalid_positions.append_array([
			existing_horizontal_2,
			existing_horizontal_2 - map.player_number,
			existing_horizontal_2 + map.player_number
		])
		invalid_positions.append_array(range(existing_horizontal_2 - 3, existing_horizontal_2 + 4))
		
		for vertical in [existing_vertical_1, existing_vertical_2]:
			invalid_positions.append_array([
				vertical,
				vertical + map.player_number,
				vertical - 1,
				vertical + (map.player_number - 1)
			])
	
	# Position 
	var invalid_floors = []
	invalid_floors = [32,33,34,35]
	invalid_positions += invalid_floors
	
	return not (id in invalid_positions)

func is_valid_vertical_block(id: int, existing_horizontal_1: int, existing_horizontal_2: int, existing_vertical_1: int, existing_vertical_2: int, existing_horizontal_special: int, vertical_string: String) -> bool:
	var invalid_positions = []
	
	for horizontal in [existing_horizontal_1, existing_horizontal_2]:
		invalid_positions.append_array([
			horizontal,
			horizontal - (map.player_number - 1),
			horizontal - map.player_number,
			horizontal + 1
		])
	
	if vertical_string in ["block_vertical_2", "block_vertical_special"]:
		for vertical in [existing_vertical_1, existing_vertical_2]:
			invalid_positions.append_array([
				vertical, 
				vertical + map.player_number,
				vertical - map.player_number,
				vertical - 1,
				vertical + 1
			])
	
	if vertical_string == "block_vertical_special":
		invalid_positions.append_array([
			existing_horizontal_special,
			existing_horizontal_special - (map.player_number - 1),
			existing_horizontal_special - map.player_number,
			existing_horizontal_special + 1
		])
	
	# Position 
	var invalid_floors = []
	invalid_floors = [32,33,34,35]
	invalid_positions += invalid_floors
	
	#print("invalid_positions : ", id in invalid_positions)
	return not (id in invalid_positions)

# Generate ids and check it if there's execption array for generate the new id
func generate_random_ids(min_id: int, max_id: int, count: int, exclude_ids: Array = [], obstacle_string: String = "null") -> Array:
	var available_ids: Array = range(min_id, max_id + 1)
	# Checking level
	var _occupied_ids = []
	if map.player_number == 4:
		if map.current_level_id == 0:
			_occupied_ids = [9,20,31]
		elif map.current_level_id == 4:
			_occupied_ids = [11,35]
	exclude_ids += _occupied_ids
	
	for id in exclude_ids:
		available_ids.erase(id)
	
	var new_array: Array = []
	
	for i in range(count):
		var valid_ids: Array = []
		
		for id in available_ids:
			var is_valid = true
			
			match obstacle_string:
				"boost":
					if is_adjacent_to_existing(id, new_array):
						is_valid = false
				"boost_special":
					if is_adjacent_to_existing(id, boosts_id_array):
						is_valid = false
				"block":
					match i:
						0: pass  # No restrictions for the first block
						1: 
							if not is_valid_horizontal_block(id, new_array[0], 0, 0, 0, "block_horizontal_2"):
								is_valid = false
						2:
							if not is_valid_vertical_block(id, new_array[0], new_array[1], 0, 0, 0, "block_vertical_1"):
								is_valid = false
						3:
							if not is_valid_vertical_block(id, new_array[0], new_array[1], new_array[2], 0, 0, "block_vertical_2"):
								is_valid = false
				"block_special":
					match i:
						0:
							if not is_valid_horizontal_block(id, blocks_id_array[0], blocks_id_array[1], blocks_id_array[2], blocks_id_array[3], "block_horizontal_special"):
								is_valid = false
						1:
							if not is_valid_vertical_block(id, blocks_id_array[0], blocks_id_array[1], blocks_id_array[2], blocks_id_array[3], new_array[0], "block_vertical_special"):
								is_valid = false
			if is_valid:
				#print("valid id append : ", id)
				valid_ids.append(id)
		
		if valid_ids.is_empty():
			break  # No more valid IDs available
		
		if obstacle_string == "block" and new_array.size() >= 2: # Which mean its vertical block
			excludes_vertical_ids(valid_ids)
		if obstacle_string == "block_special" and new_array.size() >= 1: # Which mean its vertical block special
			excludes_vertical_ids(valid_ids)
		
		# Choose the id from valid_ids
		var random_id = valid_ids[randi() % valid_ids.size()]
		new_array.append(random_id)
		available_ids.erase(random_id)
		
		#print("%s blocks: %s" % [["First horizontal", "Second horizontal", "First vertical", "Second vertical"][i], valid_ids])
	
	return new_array

func excludes_vertical_ids(valid_array):
	var excludes_array 
	match map.player_number:
		3:
			excludes_array = [3,6,9,12,15,18,21,24]
		4:
			excludes_array = [4,8,12,16,20,24,28,32]
		5:
			excludes_array = [5,10,15,20,25,30,35,40]
		6:
			excludes_array = [6,12,18,24,30,36,42,48]
	
	for id in excludes_array:
		valid_array.erase(id)
	
	return valid_array


# ========================================
# ===      Tiles Spawn Obstacle      ===
# ========================================
func set_tiles_spawn_material_into_obstacle_tile():
	var materials = [
		coin_tile_spawn_surface_mat,
		diamond_tile_spawn_surface_mat,
		star_tile_spawn_surface_mat,
		heart_tile_spawn_surface_mat
	]
	
	for index in tiles_spawn_id_array.size():
		var selected_tiles_id = tiles_spawn_id_array[index]
		var obstacle_tile_mesh = floors_and_tiles_regions.tiles_array[selected_tiles_id].get_node("obstacle_tile")
		
		# Assign the material based on the index
		if index < materials.size():
			obstacle_tile_mesh.set_surface_override_material(0, materials[index])
		
		obstacle_tile_mesh.show()

func set_tiles_spawn_special_material_into_obstacle_tile():
	var materials = [
		coin_and_heart_tile_spawn_surface_mat,
		diamond_and_star_tile_spawn_surface_mat,
	]
	
	for index in tiles_spawn_special_id_array.size():
		var selected_tiles_id = tiles_spawn_special_id_array[index]
		var obstacle_tile_mesh = floors_and_tiles_regions.tiles_array[selected_tiles_id].get_node("obstacle_tile")
		
		# Assign the material based on the index
		if index < materials.size():
			obstacle_tile_mesh.set_surface_override_material(0, materials[index])
		
		obstacle_tile_mesh.show()

# ========================================
# ===          Stack Obstacle          ===
# ========================================
func set_stack_material_into_obstacle_tile():
	for _stack_id in stacks_id_array:
		var obstacle_tile_mesh_on_current_stack_id = floors_and_tiles_regions.tiles_array[_stack_id].get_node("obstacle_tile")
		obstacle_tile_mesh_on_current_stack_id.show()
		obstacle_tile_mesh_on_current_stack_id.set_surface_override_material(0, stack_surface_mat)

func set_stack_special_material_into_obstacle_tile():
	for _stack_special_id in stacks_special_id_array:
		var obstacle_tile_mesh_on_current_stack_special_id = floors_and_tiles_regions.tiles_array[_stack_special_id].get_node("obstacle_tile")
		obstacle_tile_mesh_on_current_stack_special_id.show()
		obstacle_tile_mesh_on_current_stack_special_id.set_surface_override_material(0, stack_special_surface_mat)


# ========================================
# ===          Boost Obstacle          ===
# ========================================
func set_boost_material_into_obstacle_tile():
	var materials = [
		boost_up_surface_mat,
		boost_down_surface_mat,
		boost_left_surface_mat,
		boost_right_surface_mat
	]
	
	for index in boosts_id_array.size():
		var selected_tiles_id = boosts_id_array[index]
		var obstacle_tile_mesh = floors_and_tiles_regions.tiles_array[selected_tiles_id].get_node("obstacle_tile")
		
		# Assign the material based on the index
		if index < materials.size():
			obstacle_tile_mesh.set_surface_override_material(0, materials[index])
		
		obstacle_tile_mesh.show()

func set_boost_special_material_into_obstacle_tile():
	var materials = [
		boost_special_1_surface_mat,
		boost_special_2_surface_mat,
	]
	
	for index in boosts_special_id_array.size():
		var selected_tiles_id = boosts_special_id_array[index]
		var obstacle_tile_mesh = floors_and_tiles_regions.tiles_array[selected_tiles_id].get_node("obstacle_tile")
		
		# Assign the material based on the index
		if index < materials.size():
			obstacle_tile_mesh.set_surface_override_material(0, materials[index])
		
		obstacle_tile_mesh.show()


# ========================================
# ===          Block Obstacle          ===
# ========================================
func set_block_material_into_block_obstacle():
	var materials = [
		block_1_material_surface_mat,
		block_1_material_surface_mat,
		block_2_material_surface_mat,
		block_2_material_surface_mat,
	]
	
	for index in blocks_id_array.size():
		var selected_tiles_id = blocks_id_array[index]
		var block_horizontal = floors_and_tiles_regions.tiles_array[selected_tiles_id].get_node("block_horizontal")
		var block_vertical = floors_and_tiles_regions.tiles_array[selected_tiles_id].get_node("block_vertical")
		
		# Assign the material based on the index
		if index < materials.size() - 2:
			block_horizontal.set_surface_override_material(0, materials[index])
			block_horizontal.show()
		else:
			block_vertical.set_surface_override_material(0, materials[index])
			block_vertical.show()

func set_block_special_material_into_block_obstacle():
	var materials = [
		block_3_material_surface_mat,
		block_3_material_surface_mat,
	]
	
	for index in blocks_special_id_array.size():
		var selected_tiles_id = blocks_special_id_array[index]
		var block_horizontal = floors_and_tiles_regions.tiles_array[selected_tiles_id].get_node("block_horizontal")
		var block_vertical = floors_and_tiles_regions.tiles_array[selected_tiles_id].get_node("block_vertical")
		
		# Assign the material based on the index
		if index < materials.size() - 1:
			block_horizontal.set_surface_override_material(0, materials[index])
			block_horizontal.show()
		else:
			block_vertical.set_surface_override_material(0, materials[index])
			block_vertical.show()
