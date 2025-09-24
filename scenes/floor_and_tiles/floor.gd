extends MeshInstance3D

@onready var main = get_parent().get_parent() # or get_node("/root/main")
@onready var floors_and_tiles_regions = get_parent()
@onready var characters_manager = get_node_or_null("/root/Main/CharactersManager")
@onready var obstacles = get_node_or_null("/root/Main/Obstacles")
@onready var gui = get_node_or_null("/root/Main/Gui")
@onready var dice = get_node_or_null("/root/Main/DiceManager")
@onready var player_board = get_node_or_null("/root/Main/Gui/PlayerBoard")
@onready var floor_static_body = $floor_static_body
@onready var marker_camera = $marker_camera

var floor_slot_id
var occupied_by_player

var hover_movement_tile
var hover_tile_sprite 

func _ready():
	# Signal
	floor_static_body.connect("input_event", _on_input_event)
	#floor_static_body.connect("mouse_entered", _on_floor_entered)
	#floor_static_body.connect("mouse_exited", _on_floor_exited)

func _on_input_event(_camera, _event, _position, _normal, _shape_idx):
	#if Input.is_action_just_pressed("left_click") and player_board.is_put_item:
		#return
	
	# Check if the player left click on the floor with the spawn tile is true
	# It's mean the player want to spawn tile by clicking the tiles on arena 
	if Input.is_action_just_pressed("left_click") && Global.is_spawn_tile:
		print("spawn tile after click")
		print('floor slot id spawn tile: ', floor_slot_id)
		print('floors_and_tiles_regions.floor_id_clicked : ', floors_and_tiles_regions.floor_id_clicked)
		
		# Checking if the current floor clicked is a stack or stack special
		# If not then return
		var tiles_spawns_array = obstacles.tiles_spawn_id_array + obstacles.tiles_spawn_special_id_array
		var obstacle_tile = floors_and_tiles_regions.tiles_array[floor_slot_id].get_node("obstacle_tile")
		var obstacle_mat = obstacle_tile.get_surface_override_material(0)
		const VALID_SPAWN_TYPES = [
			"coin_and_heart_tile_spawn",
			"coin_tile_spawn",
			"diamond_and_star_tile_spawn",
			"diamond_tile_spawn",
			"heart_tile_spawn",
			"star_tile_spawn"
			]
		if not obstacle_mat or obstacle_mat.resource_name not in VALID_SPAWN_TYPES:
			return
		if floor_slot_id not in tiles_spawns_array:
			#print("floor slot id not in")
			return
		spawn_tiles()
	
	if Input.is_action_just_pressed("left_click") && !Global.is_spawn_tile:
		floors_and_tiles_regions.floor_id_clicked = floor_slot_id
		print('floor slot id : ', floor_slot_id)
	
		#var first_tile_mesh = floors_and_tiles_regions.tiles_array[floor_slot_id].get_node("token_tile")
		#var first_tile_mesh_surface = first_tile_mesh.get_surface_override_material(0)
		## Burn Tile
		#if main.current_player_node.float_actions_gui.is_burn_tile and first_tile_mesh_surface != null :
			#Global.choose_tile_for_activate_power_card.emit()
			#player_board.show()
		## Freeze
		#elif main.current_player_node.float_actions_gui.is_freeze and occupied_by_player != null:
			#Global.choose_tile_for_activate_power_card.emit()
			#player_board.show()
		## Swap pos
		#elif main.current_player_node.float_actions_gui.is_swap_pos and occupied_by_player != null:
			#Global.choose_tile_for_activate_power_card.emit()
			#player_board.show()
		## Move Stack
		#elif main.current_player_node.float_actions_gui.is_move_stack:
			#var _pc_move_stack = main.current_player_node.float_actions_gui.pc_move_stack
			#
			#if _pc_move_stack.is_item:
				#print("available floors for move stack : ", Global.available_floors_for_move_stack)
				#if floor_slot_id not in Global.available_floors_for_move_stack:
					#print("not in floor")
					#return
				## Set the stack material to choosen floor and show obstacle tile
				#var choosen_obstacle_tile_mesh = floors_and_tiles_regions.tiles_array[floor_slot_id].obstacle_tile
				#choosen_obstacle_tile_mesh.set_surface_override_material(0, _pc_move_stack.obstacle_mat)
				#choosen_obstacle_tile_mesh.show()
				#
				#
				#_pc_move_stack.choose_floor_to_place_stack.emit()
				#return
			#
			#print("pc emit move stack")
			#var _obstacle_mesh = floors_and_tiles_regions.tiles_array[floor_slot_id].get_node("obstacle_tile")
			#var _obstacle_mat = _obstacle_mesh.get_surface_override_material(0)
			#print("obstacle_mat : ", _obstacle_mat)
			#if _obstacle_mat == null:
				#return
			#if _obstacle_mat.resource_name == "stack" or _obstacle_mat.resource_name == "special_stack":
				#_pc_move_stack.choose_stack_to_move.emit()
				#player_board.show()
		#
		## Move Tile Spawn
		#elif main.current_player_node.float_actions_gui.is_move_tile_spawn:
			#var _pc_move_tile_spawn = main.current_player_node.float_actions_gui.pc_move_tile_spawn
			#
			#if _pc_move_tile_spawn.is_item:
				#print("available floors for move tile_spawn : ", Global.available_floors_for_move_tile_spawn)
				#if floor_slot_id not in Global.available_floors_for_move_tile_spawn:
					#print("not in floor")
					#return
				## Set the tile_spawn material to choosen floor and show obstacle tile
				#var choosen_obstacle_tile_mesh = floors_and_tiles_regions.tiles_array[floor_slot_id].obstacle_tile
				#choosen_obstacle_tile_mesh.set_surface_override_material(0, _pc_move_tile_spawn.obstacle_mat)
				#choosen_obstacle_tile_mesh.show()
				#
				#
				#_pc_move_tile_spawn.choose_floor_to_place_tile_spawn.emit()
				#return
			#
			#print("pc emit move tile_spawn")
			#var _obstacle_mesh = floors_and_tiles_regions.tiles_array[floor_slot_id].get_node("obstacle_tile")
			#var _obstacle_mat = _obstacle_mesh.get_surface_override_material(0)
			#
			#if _obstacle_mat == null:
				#return
			#if _obstacle_mat.resource_name in Global.tiles_spawns_resource_name:
				#print("obstacle_mat res name : ", _obstacle_mat.resource_name)
				#_pc_move_tile_spawn.choose_tile_spawn_to_move.emit()
				#player_board.show()
#
		## Move Block
		#elif main.current_player_node.float_actions_gui.is_move_block:
			#var _pc_move_block = main.current_player_node.float_actions_gui.pc_move_block
			#
			#if _pc_move_block.is_item:
				#print("available floors for move block : ", Global.available_floors_for_move_block)
				#if floor_slot_id not in Global.available_floors_for_move_block:
					#print("not in floor")
					#return
				## Set the block material to choosen floor and show block tile
				#var choosen_block_mesh 
				#if _pc_move_block.floor_choose_id == _pc_move_block.obstacles_all_blocks_ids[0] or _pc_move_block.floor_choose_id == _pc_move_block.obstacles_all_blocks_ids[1]:
					#choosen_block_mesh = floors_and_tiles_regions.tiles_array[floor_slot_id].block_horizontal
				#else:
					#choosen_block_mesh = floors_and_tiles_regions.tiles_array[floor_slot_id].block_vertical
				#
				#print("block mesh : ", choosen_block_mesh.name)
				#choosen_block_mesh.set_surface_override_material(0, _pc_move_block.block_mat)
				#choosen_block_mesh.show()
				#_pc_move_block.choose_floor_to_place_block.emit()
				#return
			#
			#print("pc emit move block")
			#var _block_horizontal_mesh = floors_and_tiles_regions.tiles_array[floor_slot_id].get_node("block_horizontal")
			#var _block_horizontal_mat = _block_horizontal_mesh.get_surface_override_material(0)
			#var _block_vertical_mesh = floors_and_tiles_regions.tiles_array[floor_slot_id].get_node("block_vertical")
			#var _block_vertical_mat = _block_vertical_mesh.get_surface_override_material(0)
			#
			#
			## Check Block Horizontal
			#if _block_horizontal_mat != null:
				#if _block_horizontal_mat.resource_name in Global.block_spawns_resource_name :
					#print("block horizontal res name : ", _block_horizontal_mat.resource_name)
					#print("emit chose block")
					#_pc_move_block.choose_block_to_move.emit()
					#player_board.show()
			#if _block_vertical_mat != null:
				#if _block_vertical_mat.resource_name in Global.block_spawns_resource_name :
					#print("block vertical res name : ", _block_vertical_mat.resource_name)
					#print("emit chose block")
					#_pc_move_block.choose_block_to_move.emit()
					#player_board.show()
			#return
		#
		## Move Boost
		#elif main.current_player_node.float_actions_gui.is_move_boost:
			#var _pc_move_boost = main.current_player_node.float_actions_gui.pc_move_boost
			#
			#if _pc_move_boost.is_item:
				#print("available floors for move boost : ", Global.available_floors_for_move_boost)
				#if floor_slot_id not in Global.available_floors_for_move_boost:
					#print("not in floor")
					#return
				## Set the boost material to choosen floor and show obstacle tile
				#var choosen_obstacle_tile_mesh = floors_and_tiles_regions.tiles_array[floor_slot_id].obstacle_tile
				#choosen_obstacle_tile_mesh.set_surface_override_material(0, _pc_move_boost.obstacle_mat)
				#choosen_obstacle_tile_mesh.show()
				#
				#_pc_move_boost.choose_floor_to_place_boost.emit()
				#return
			#
			#print("pc emit move boost")
			#var _obstacle_mesh = floors_and_tiles_regions.tiles_array[floor_slot_id].get_node("obstacle_tile")
			#var _obstacle_mat = _obstacle_mesh.get_surface_override_material(0)
			#
			#if _obstacle_mat == null:
				#return
			#if _obstacle_mat.resource_name in Global.boost_spawns_resource_name:
				#print("obstacle_mat res name : ", _obstacle_mat.resource_name)
				#_pc_move_boost.choose_boost_to_move.emit()
				#player_board.show()
		#
		## Move Racer
		#elif main.current_player_node.float_actions_gui.is_move_racer and occupied_by_player != null:
			#print("move racer floor click")
			#Global.choose_tile_for_activate_power_card.emit()
		## Put Back
		#elif main.current_player_node.float_actions_gui.is_put_back and floor_slot_id in main.current_player_node.float_actions_gui.pc_put_back.available_floors:
			#print('put back tile in choosen floor')
			## Load texture to put in the choosen floor
			#main.current_player_node.float_actions_gui.pc_put_back.set_tile_to_choosen_floor(floor_slot_id)
			#
			## Set camera to floor
			#main.current_camera.follow_target = marker_camera
			#main.current_camera.set_priority(10)
			#main.camera_tactic.set_priority(0)
			#await get_tree().create_timer(1.5).timeout
			#Global.put_back_to_floor.emit()
			#pass
		## Book tile
		#elif main.current_player_node.float_actions_gui.is_book_tiles and floor_slot_id in main.current_player_node.float_actions_gui.pc_book_tiles.available_floors:
			## Load the 3D texture on the tile.tscn
			#await main.current_player_node.float_actions_gui.pc_book_tiles.set_book_tiles(floor_slot_id)
			#floors_and_tiles_regions.floor_id_clicked = null
			#await get_tree().create_timer(0.5).timeout
			#Global.book_tiles_done.emit()
		#else:
		if main.current_player_node.is_currently_controlled and not Global.is_power_card_active:
			print("Requesting player to move to floor: ", floor_slot_id)
			# Call the new move_to function on the current player character
			main.current_player_node.move_to(self.global_transform.origin)
		else:
			# If it's not a valid move, do nothing.
			return


func spawn_tiles():
	main.current_player_node.animation_player.play("animation-pack/spawn_tile_1")
	#main.current_player_node.animation_player.play("spawn_tile_1")
	
	# Set the floor_id_click into null, incase the player not moving. 
	# When we selected the tiles the player not move to the tiles we clicked
	#floors_and_tiles_regions.floor_id_clicked = null
	
	print("spawn active")
	# Emit the spawn is active
	Global.spawn_active.emit()
	# Player spawn tiles
	player_select_spawn_tile() # Main focus on spawn tiles


func _on_floor_entered():
	#print("floor enterd")
	var tile_node = floors_and_tiles_regions.tiles_array[floor_slot_id]
	var token_tile = tile_node.get_node("token_tile")
	var token_tile_surface = token_tile.get_surface_override_material(0) 
	var obstacle_tile = tile_node.get_node("obstacle_tile")
	var obstacle_surface = obstacle_tile.get_surface_override_material(0) 
	var hover_movement_tile = tile_node.get_node("hover_movement_tile")

	if floor_slot_id in characters_manager.adjacents_array and main.current_player_node.is_currently_controlled and !Global.is_power_card_active:
		hover_tile_sprite = tile_node.get_node("hover_tile")
		hover_tile_sprite.show()
	
	if Global.is_power_card_active and hover_movement_tile.visible:
		hover_tile_sprite = tile_node.get_node("hover_tile")
		hover_tile_sprite.show()
	
	if token_tile_surface != null and obstacle_surface != null:
		# Set hover state
		tile_node.set_hover_state(true)
		
		# Make sure we have a unique material instance
		if token_tile_surface.resource_path != "":  # Check if it's not already a unique instance
			token_tile_surface = token_tile_surface.duplicate(true)
			token_tile.set_surface_override_material(0, token_tile_surface)
		token_tile_surface.set_albedo(Color(1, 1, 1, 0.17))

func _on_floor_exited():
	#print("floor exited")
	var tile_node = floors_and_tiles_regions.tiles_array[floor_slot_id]
	var token_tile = tile_node.get_node("token_tile")
	var token_tile_surface = token_tile.get_surface_override_material(0) 
	var obstacle_tile = tile_node.get_node("obstacle_tile")
	var obstacle_surface = obstacle_tile.get_surface_override_material(0) 

	if floor_slot_id in characters_manager.adjacents_array:
		hover_tile_sprite = tile_node.get_node("hover_tile")
		hover_tile_sprite.hide()
	
	if Global.is_power_card_active:
		hover_tile_sprite = tile_node.get_node("hover_tile")
		hover_tile_sprite.hide()
	
	if token_tile_surface != null and obstacle_surface != null:
		# Reset hover state
		tile_node.set_hover_state(false)
		
		# Make sure we have a unique material instance
		if token_tile_surface.resource_path != "":  # Check if it's not already a unique instance
			token_tile_surface = token_tile_surface.duplicate(true)
			token_tile.set_surface_override_material(0, token_tile_surface)
		token_tile_surface.set_albedo(Color(1, 1, 1, 1))


# ========================================
# ===        Player Spawn Tiles        ===
# ========================================
#region Player Spawn Tiles
func player_select_spawn_tile():
	if (floor_slot_id in obstacles.tiles_spawn_id_array) or (floor_slot_id in obstacles.tiles_spawn_special_id_array):
		var tile_node = floors_and_tiles_regions.tiles_array[floor_slot_id]
		var obstacle_mesh = tile_node.get_node("obstacle_tile")
		var book_tiles = tile_node.get_node("book_tiles")
		var spawn_type = obstacle_mesh.get_surface_override_material(0).resource_name
		print("spawn_type: ", spawn_type)

		main.current_camera.set_priority(0)
		main.camera_tactic.set_priority(10)

		dice.show()
		dice.roll()
		
		# Check dice result
		match dice.final_result:
			5: # Zonk
				await get_tree().create_timer(2.0).timeout
				set_variable_after_spawn()
				return 

		#await Global.dice_rolled

		await get_tree().create_timer(2.0).timeout
		print("dice rolled continue to spawn")

		var tile_data = get_tile_data_for_spawn(spawn_type)
		if tile_data:
			rule_spawn_tile(tile_data.hologram, tile_data.common)
		# Book tiles
		if book_tiles.visible:
			book_tiles.visible = false
			
	set_variable_after_spawn()

func set_variable_after_spawn():
	if dice.final_result == 5:
		pass
	elif dice.final_result == 2:
		main.current_camera.follow_target = main.current_player_node.marker_camera
	else:
		main.current_camera.follow_target = self.marker_camera
	main.current_camera.set_priority(10)
	main.camera_tactic.set_priority(0)
	# Decrease the player actions
	await get_tree().create_timer(1.5).timeout
	# Check the action, if player on a boost obstacle
	main.current_player_node.float_actions_gui.check_action_if_player_on_boost_obstacle()
	# Check if the player action is 1 and is_player_clicked is false, then show the action gui
	# It's mean the player already move but not doing the actions
	if !main.current_player_node.is_player_clicked and main.player_actions == 1:
		main.current_player_node.show_float_gui()
	# Hover tiles
	floors_and_tiles_regions.hover_adjacents_floor()
	
	# temp
	var tile = floors_and_tiles_regions.tiles_array[floor_slot_id]
	tile.book_tiles.hide()
	
	main.player_actions -= 1
	main.current_camera.follow_target = main.current_player_node.marker_camera
	Global.is_spawn_tile = false
	
	gui.show_or_hide_for_spawn_tile(true)
	main.current_player_node.float_actions_gui.unhover_spawn_tile()
	

# Get the tile data for spawn 
func get_tile_data_for_spawn(spawn_type):
	var random_id = randi_range(0,1)

	match spawn_type:
		"star_tile_spawn":
			return {"hologram": Global.star_hologram_tile_surface_mat.duplicate(true), "common": Global.star_tile_surface_mat.duplicate(true)}
		"diamond_tile_spawn":
			return {"hologram": Global.diamond_hologram_tile_surface_mat.duplicate(true), "common": Global.diamond_tile_surface_mat.duplicate(true)}
		"heart_tile_spawn":
			return {"hologram": Global.heart_hologram_tile_surface_mat.duplicate(true), "common": Global.heart_tile_surface_mat.duplicate(true)}
		"coin_tile_spawn":
			return {"hologram": Global.coin_hologram_tile_surface_mat.duplicate(true), "common": Global.coin_tile_surface_mat.duplicate(true)}
		"coin_and_heart_tile_spawn":
			if random_id == 0:
				return {"hologram": Global.coin_hologram_tile_surface_mat.duplicate(true), "common": Global.coin_tile_surface_mat.duplicate(true)}
			else:
				return {"hologram": Global.heart_hologram_tile_surface_mat.duplicate(true), "common": Global.heart_tile_surface_mat.duplicate(true)}
		"diamond_and_star_tile_spawn":
			print("diamond and star")
			if random_id == 0:
				return {"hologram": Global.diamond_hologram_tile_surface_mat.duplicate(true), "common": Global.diamond_tile_surface_mat.duplicate(true)}
			else:
				return {"hologram": Global.star_hologram_tile_surface_mat.duplicate(true), "common": Global.star_tile_surface_mat.duplicate(true)}
	return null

# Rule for spawn tile where is the tile 
func rule_spawn_tile(tiles_hologram, tiles_common):
	var tile_to_spawn = choose_hologram_or_common_tiles(tiles_hologram, tiles_common)
	var available_spawn_arr = []
	match main.player_number:
		3:
			if floor_slot_id in [3,5,6,8,9,11,12,14,15,17,18,20,21,23,24,26]:
				tiles_spawn_for_current_floor(tile_to_spawn)
		4:
			for i in range(4, 36):
				available_spawn_arr.append(i)
			if floor_slot_id in available_spawn_arr:
				tiles_spawn_for_current_floor(tile_to_spawn)
		5:
			if floor_slot_id in [5,10,15,19,20,24,25,29,30,34,35,39,40,44]:
				tiles_spawn_for_current_floor(tile_to_spawn)
		6:
			if floor_slot_id in [6,11,12,17,18,23,24,29,30,35,36,41,42,47,48,53]:
				tiles_spawn_for_current_floor(tile_to_spawn)

# Choose hologram or common tile to spawn 
func choose_hologram_or_common_tiles(tiles_hologram, tiles_common):
	var tile_choosen
	match dice.final_result:
		1,6 : tile_choosen = tiles_common
		2: 
			floor_slot_id = main.current_player_node.current_player_floor_id 
			tile_choosen = tiles_common
		3,4 : tile_choosen = tiles_hologram
			
	return tile_choosen

# Spawn tile for the current tiles 
func tiles_spawn_for_current_floor(tile_source):
	var token_tile = floors_and_tiles_regions.tiles_array[floor_slot_id].get_node("token_tile")
	token_tile.set_surface_override_material(0, tile_source)
	token_tile.show()
