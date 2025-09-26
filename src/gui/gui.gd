extends Control

# Get references to the nodes needed to update the UI
@onready var floors_and_tiles_regions = get_node("/root/Main/FloorsAndTileManager")
@onready var obstacles = get_node("/root/Main/Obstacles")

const coin_obstacle_animation = preload("res://assets/materials/obstacle_animation/coin_obstacle_animation.tres")
const diamond_obstacle_animation = preload("res://assets/materials/obstacle_animation/diamond_obstacle_animation.tres")
const heart_obstacle_animation = preload("res://assets/materials/obstacle_animation/heart_obstacle_animation.tres")
const star_obstacle_animation = preload("res://assets/materials/obstacle_animation/star_obstacle_animation.tres")


# This is the function you are moving here from float_actions_gui.gd
func hover_tiles_for_spawn_tile_action():
	for _id in obstacles.tiles_spawn_id_array:
		var obstacle_tile = floors_and_tiles_regions.tiles_array[_id].get_node("obstacle_tile")
		var obstacle_tile_animation = floors_and_tiles_regions.tiles_array[_id].get_node("obstacle_tile_animation")
		
		# Set the scale and UV for the obstacle tile
		obstacle_tile.scale = Vector3(1.1 ,1.1 ,1.1)
		obstacle_tile.get_surface_override_material(0).set_uv1_scale(Vector3(0.85,0.85,0.85))
		obstacle_tile.get_surface_override_material(0).set_uv1_offset(Vector3(0.075,0.075,0))
		
		# Set the colors of the Shaders of obstacle_tile_animation
		# Coin Tile
		if _id == obstacles.tiles_spawn_id_array[0]:
			obstacle_tile_animation.set_surface_override_material(0, coin_obstacle_animation)
		# Diamond Tile
		elif _id == obstacles.tiles_spawn_id_array[1] :
			obstacle_tile_animation.set_surface_override_material(0, diamond_obstacle_animation)
		# Star Tile
		elif _id == obstacles.tiles_spawn_id_array[2] :
			obstacle_tile_animation.set_surface_override_material(0, star_obstacle_animation)
		# Heart Tile
		elif _id == obstacles.tiles_spawn_id_array[3] :
			obstacle_tile_animation.set_surface_override_material(0, heart_obstacle_animation)
		obstacle_tile_animation.show()

# This function has been moved from float_actions_gui.gd
func unhover_spawn_tile():
	var hover_movement_mesh
	for _id in obstacles.tiles_spawn_id_array:
		var obstacle_tile = floors_and_tiles_regions.tiles_array[_id].get_node("obstacle_tile")
		var obstacle_tile_animation = floors_and_tiles_regions.tiles_array[_id].get_node("obstacle_tile_animation")
		
		obstacle_tile.scale = Vector3(1.24, 1.24, 1.24)
		obstacle_tile.get_surface_override_material(0).set_uv1_scale(Vector3(1,1,1))
		obstacle_tile.get_surface_override_material(0).set_uv1_offset(Vector3(0,0,0))
		
		hover_movement_mesh = floors_and_tiles_regions.tiles_array[_id].get_node("hover_movement_tile")
		hover_movement_mesh.hide()
		obstacle_tile_animation.hide()
