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
	if not _event is InputEventMouseButton or not _event.is_pressed(): return
	print("local player : ", main.turn_manager.is_local_players_turn() )
	if not main.turn_manager.is_local_players_turn():
		return
		
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
	
	elif Input.is_action_just_pressed("left_click") and not Global.is_spawn_tile:
		floors_and_tiles_regions.floor_id_clicked = floor_slot_id
		
		# Handle player movement
		if not Global.is_power_card_active:
			if floor_slot_id in characters_manager.adjacents_array:
				print("player movement ")
				main.current_player_node.move_to(self.global_transform.origin, floor_slot_id)
			else:
				print("Invalid move: Floor %d is not an adjacent tile." % floor_slot_id)


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
