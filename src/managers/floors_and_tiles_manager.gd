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
	# This function now only sets up the scene references.
	# The responsibility for building the level is now in main.gd.
	resources["floor"]["scene"] = floor_scene
	resources["tile"]["scene"] = tile_scene

# Unhover the adjacents floor when player want move 
func hover_adjacents_floor():
	var hover_movement_mesh
	for id_adjacent in characters_manager.adjacents_array:
		if id_adjacent >= tiles_array.size(): continue
		hover_movement_mesh = tiles_array[id_adjacent].get_node("hover_movement_tile")
		hover_movement_mesh.set_surface_override_material(0, move_material)
		hover_movement_mesh.show()
	
	for id_occupied in characters_manager.occupied_adjacents_array:
		if id_occupied >= tiles_array.size(): continue
		hover_movement_mesh = tiles_array[id_occupied].get_node("hover_movement_tile")
		hover_movement_mesh.set_surface_override_material(0, blocked_material)
		hover_movement_mesh.show()

# Unhover the adjacents floor when player already move 
# or when the player is_clicked is true
func unhover_adjacents_floor():
	var hover_movement_mesh
	print("unhover floor")
	for id_adjacent in characters_manager.adjacents_array:
		if id_adjacent >= tiles_array.size(): continue
		hover_movement_mesh = tiles_array[id_adjacent].get_node("hover_movement_tile")
		hover_movement_mesh.hide()
		
	for id_occupied in characters_manager.occupied_adjacents_array:
		if id_occupied >= tiles_array.size(): continue
		hover_movement_mesh = tiles_array[id_occupied].get_node("hover_movement_tile")
		hover_movement_mesh.hide()
	
	for i in range(tiles_array.size()):
		hover_movement_mesh = tiles_array[i].get_node("hover_movement_tile")
		hover_movement_mesh.hide()

func instantiate_resources(resource_type: String):
	for i in range(main.default_rows * main.player_number):
		var resource_instance = resources[resource_type]["scene"].instantiate()
		# Set a consistent name for host and clients
		resource_instance.name = "%s_%d" % [resource_type, i]
		if resource_type == "floor":
			# Use the loop index for a consistent ID
			resource_instance.floor_slot_id = i
		resource_instance.position.y = resources[resource_type]["y_offset"]
		resources[resource_type]["array"].append(resource_instance)
		add_child(resource_instance)

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

# This function is now called only by the host to generate the tile layout data.
func generate_random_tile_data() -> Dictionary:
	var tile_data = {}
	var player_count = main.player_number
	var total_tiles = player_count * main.default_rows
	
	var ids = []
	var max_id_for_spawn = total_tiles - player_count
	for i in range(player_count, max_id_for_spawn):
		ids.append(i % 4)
	ids.shuffle()
	
	var hologram_counters = [0, 0, 0, 0]
	var hologram_positions = []
	var first_12_indices = range(12)
	first_12_indices.shuffle()
	for i in range(3):
		hologram_positions.append(first_12_indices[i])
	
	for i in range(total_tiles):
		# This function now generates data without assuming the nodes exist yet.
		# It relies on set_tiles_from_data to actually apply the materials.
		if i >= player_count and i < max_id_for_spawn:
			var material_index = ids[ (i - player_count) % ids.size()]
			var is_hologram = false
			
			if i < 12 and i in hologram_positions:
				is_hologram = true
			elif i >= 12 and randf() < 0.1 and hologram_counters[material_index] < 3: # 10% chance
				is_hologram = true
			
			if is_hologram:
				hologram_counters[material_index] += 1

			tile_data[i] = {"is_hologram": is_hologram, "mat_index": material_index}
			
	return tile_data

# CLIENT & HOST: Builds the level from data received from the host.
func build_from_data(state: Dictionary):
	# Clear existing resources if any, to prevent conflicts on rebuild
	for c in get_children():
		c.queue_free()
	
	# Wait a frame to ensure old nodes are gone before adding new ones
	await get_tree().process_frame

	for res_type in resources:
		resources[res_type]["array"].clear()
		resources[res_type]["vector_x"].clear()
		resources[res_type]["vector_z"].clear()

	var player_count = state.get("player_number", 4)
	var row_count = state.get("default_rows", 10)
	main.player_number = player_count
	main.default_rows = row_count

	# Re-instantiate based on state data
	for resource_type in resources.keys():
		instantiate_resources(resource_type)
		generate_resource_coords(resource_type)
		set_resource_positions(resource_type)
	
	floors_array = resources["floor"]["array"]
	tiles_array = resources["tile"]["array"]
	
	# Use the received tile data to set materials
	var tile_data = state.get("tiles", {})
	set_tiles_from_data(tile_data)
	
	hide_tiles_on_start_and_finish_line()
	hide_tiles_on_specific_level_arena()

# CLIENT & HOST: Applies tile materials from synced data.
func set_tiles_from_data(tile_data: Dictionary):
	for i_str in tile_data.keys():
		var i = int(i_str)
		if i < tiles_array.size():
			var data = tile_data[i_str]
			var is_hologram = data["is_hologram"]
			var mat_index = data["mat_index"]
			
			var material_path
			if is_hologram:
				material_path = Global.tiles_hologram_surface_material[mat_index]
			else:
				material_path = Global.tiles_surface_material[mat_index]
			
			var token_tile = tiles_array[i].get_node("token_tile")
			token_tile.set_surface_override_material(0, load(material_path))

# Hide tiles on start and finish line 
func hide_tiles_on_start_and_finish_line():
	if tiles_array.is_empty(): return
	var player_count = main.player_number
	var tiles_per_line = player_count
	var total_tiles = tiles_array.size()
	# Hide tiles at the start
	for id in range(tiles_per_line):
		if id < tiles_array.size():
			tiles_array[id].get_node("token_tile").hide()
	# Hide tiles at the finish
	for id in range(total_tiles - tiles_per_line, total_tiles):
		if id < tiles_array.size():
			tiles_array[id].get_node("token_tile").hide()

func hide_tiles_on_specific_level_arena():
	if tiles_array.is_empty(): return
	# 0 = Bridge, 1 = Farm, 2 =  Forest, 3 =  Mine, 4 = Water
	if main.player_number == 4:
		# Bridge
		if main.current_level_id == 0:
			var level_bridge_arr = [9,20,31]
			for id in level_bridge_arr:
				if id < tiles_array.size(): tiles_array[id].hide()
		# Water arena 4 players
		elif main.current_level_id == 4 :
			var level_water_arr = [11,35]
			for id in level_water_arr:
				if id < tiles_array.size(): tiles_array[id].hide()
