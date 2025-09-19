extends Node3D
class_name FloorAndTilesManager

# Scene Tree
@onready var main = $".."
@onready var characters_manager = $"../CharactersManager"
@onready var obstacles = $"../Obstacles"


# Preload Scenes
@export var floor_scene: PackedScene = preload("res://scenes/floor_and_tiles/floor.tscn")
@export var tile_scene: PackedScene = preload("res://scenes/floor_and_tiles/tile.tscn")

const move_material = preload("res://assets/meshes/tiles_mesh/move_material.tres")
const blocked_material = preload("res://assets/meshes/tiles_mesh/blocked_material.tres")

# Resource Arrays
var resources = {
	"floor": {
		"array": [],
		"vector_x": [],
		"vector_z": [],
		"scene": null,
		"y_offset": 0
	},
	"tile": {
		"array": [],
		"vector_x": [],
		"vector_z": [],
		"scene": null,
		"y_offset": 0.6
	}
}

var floors_array : Array = []
var tiles_array : Array = []

var floor_id_clicked = 0


func _ready():
	resources["floor"]["scene"] = floor_scene
	resources["tile"]["scene"] = tile_scene
	
	for resource_type in resources.keys():
		instantiate_resources(resource_type)
		generate_resource_coords(resource_type)
		set_resource_positions(resource_type)
	floors_array = resources["floor"]["array"]
	tiles_array = resources["tile"]["array"]
	
	#generate_unique_tile_for_stack()
	hide_tiles_on_start_and_finish_line()
	set_tiles_surface_with_random_tiles()
	
	hide_tiles_on_specific_level_arena()

func _process(delta):
	for _id in range(main.player_number * main.default_rows):
		floors_array[_id].floor_slot_id = _id

# Unhover the adjacents floor when player want move 
func hover_adjacents_floor():
	#print("characters_manager.adjacents_array : ", characters_manager)
	var hover_movement_mesh
	for id_adjacent in characters_manager.adjacents_array:
		#print("floor hover adj")
		hover_movement_mesh = tiles_array[id_adjacent].get_node("hover_movement_tile")
		hover_movement_mesh.set_surface_override_material(0, move_material)
		hover_movement_mesh.show()
	
	for id_occupied in characters_manager.occupied_adjacents_array:
		#print("floor hover occ adj")
		hover_movement_mesh = tiles_array[id_occupied].get_node("hover_movement_tile")
		hover_movement_mesh.set_surface_override_material(0, blocked_material)
		hover_movement_mesh.show()

# Unhover the adjacents floor when player already move 
# or when the player is_clicked is true
func unhover_adjacents_floor():
	var hover_movement_mesh
	print("unhover floor")
	for id_adjacent in characters_manager.adjacents_array:
		hover_movement_mesh = tiles_array[id_adjacent].get_node("hover_movement_tile")
		hover_movement_mesh.hide()
		
	for id_occupied in characters_manager.occupied_adjacents_array:
		hover_movement_mesh = tiles_array[id_occupied].get_node("hover_movement_tile")
		hover_movement_mesh.hide()
	
	for id_occupied in range(0, floors_array.size()):
		hover_movement_mesh = tiles_array[id_occupied].get_node("hover_movement_tile")
		hover_movement_mesh.hide()

func instantiate_resources(resource_type: String):
	for i in range(main.default_rows * main.player_number):
		var resource_instance = resources[resource_type]["scene"].instantiate()
		if resource_type == "floor":
			resource_instance.floor_slot_id = resources[resource_type]["array"].size()
		resource_instance.position.y = resources[resource_type]["y_offset"]
		resources[resource_type]["array"].append(resource_instance)
		add_child(resource_instance, true)

func generate_resource_coords(resource_type: String):
	for x in range(main.default_rows):
		for z in range(main.player_number):
			resources[resource_type]["vector_x"].append(x)
			resources[resource_type]["vector_z"].append(z)

func set_resource_positions(resource_type: String):
	var z_offset = 0.15 if resource_type == "tile" else 0.0
	for i in range(main.default_rows * main.player_number):
		var resource = resources[resource_type]["array"][i]
		var x = resources[resource_type]["vector_x"][i]
		var z = resources[resource_type]["vector_z"][i] + z_offset
		resource.position.x = x
		resource.position.z = z

# Modify the set_tiles_surface_with_random_tiles function

func set_tiles_surface_with_random_tiles():
	var player_count = main.player_number
	var total_tiles = tiles_array.size()
	var surface_materials = [
	Global.coin_tile_surface_mat,
	Global.diamond_tile_surface_mat,
	Global.heart_tile_surface_mat,
	Global.star_tile_surface_mat
	]
	var hologram_materials = [
	Global.coin_hologram_tile_surface_mat,
	Global.diamond_hologram_tile_surface_mat,
	Global.heart_hologram_tile_surface_mat,
	Global.star_hologram_tile_surface_mat
	]
	
	# Generate IDs that repeat until player_number * 10
	var ids = []
	var max_id_for_spawn = (player_count * main.default_rows) - player_count
	for i in range(player_count, max_id_for_spawn ):
		ids.append(i % 4)

	# Shuffle the IDs to randomize the order
	ids.shuffle()
	#print("ids ", ids)
	# Initialize hologram counters
	var hologram_counters = [0, 0, 0, 0]
	var hologram_positions = []

	# Ensure 3 holograms in the first 12 indices
	var first_12_indices = range(12)
	first_12_indices.shuffle()
	for i in range(3):
		hologram_positions.append(first_12_indices[i])
		
	# Apply surface materials to obstacle tiles
	for i in range(total_tiles):
		var tile = tiles_array[i]
		var token_tile = tile.get_node("token_tile")
		
		if token_tile and token_tile.visible:
			var material_index = ids[i % ids.size()]
			
			var is_hologram = false
			if i < 12 and i in hologram_positions:
				is_hologram = true
			elif i >= 12 and randf() and hologram_counters[material_index] < 3:  # 10% chance after first 12
				is_hologram = true
			
			if is_hologram:
				token_tile.set_surface_override_material(0, hologram_materials[material_index])
				hologram_counters[material_index] += 1
			else:
				token_tile.set_surface_override_material(0, surface_materials[material_index])


# Hide tiles on start and finish line 
func hide_tiles_on_start_and_finish_line():
	var player_count = main.player_number
	var tiles_per_line = player_count
	var total_tiles = resources["tile"]["array"].size()
	# Hide tiles at the start
	for id in range(tiles_per_line):
		resources["tile"]["array"][id].get_node("token_tile").hide()
		resources["tile"]["array"][id].get_node("token_tile").set_surface_override_material(0, null)
		resources["tile"]["array"][id].get_node("token_tile2").hide()
		resources["tile"]["array"][id].get_node("token_tile2").set_surface_override_material(0, null)
		resources["tile"]["array"][id].get_node("token_tile3").hide()
		resources["tile"]["array"][id].get_node("token_tile3").set_surface_override_material(0, null)
		resources["tile"]["array"][id].get_node("obstacle_tile").hide()
		resources["tile"]["array"][id].get_node("tile_hologram").hide()
	# Hide tiles at the finish
	for id in range(total_tiles - tiles_per_line, total_tiles):
		resources["tile"]["array"][id].get_node("token_tile").hide()
		resources["tile"]["array"][id].get_node("token_tile").set_surface_override_material(0, null)
		resources["tile"]["array"][id].get_node("token_tile2").hide()
		resources["tile"]["array"][id].get_node("token_tile2").set_surface_override_material(0, null)
		resources["tile"]["array"][id].get_node("token_tile3").hide()
		resources["tile"]["array"][id].get_node("token_tile3").set_surface_override_material(0, null)
		resources["tile"]["array"][id].get_node("obstacle_tile").hide()
		resources["tile"]["array"][id].get_node("tile_hologram").hide()

func hide_tiles_on_specific_level_arena():
	# 0 = Bridge, 1 = Farm, 2 =  Forest, 3 =  Mine, 4 = Water
	if main.player_number == 4:
		# Bridge
		if main.current_level_id == 0:
			var level_bridge_arr = [9,20,31]
			for id in level_bridge_arr:
				tiles_array[id].hide()
				tiles_array[id].token_tile.set_surface_override_material(0, null)
		# Water arena 4 players
		elif main.current_level_id == 4 :
			var level_water_arr = [11,35]
			for id in level_water_arr:
				tiles_array[id].hide()
				tiles_array[id].token_tile.set_surface_override_material(0, null)
	
	
	#if map.current_level_id == 4 and map.player_number == 5:
		#var level_water_arr = [14,15,20,25,44,45]
		#for id in level_water_arr:
			#tiles_array[id].hide()
	#if map.current_level_id == 0 and map.player_number == 6:
		#var level_bridge_arr = [13,28,29,30,45,54]
		#for id in level_bridge_arr:
			#tiles_array[id].hide()
