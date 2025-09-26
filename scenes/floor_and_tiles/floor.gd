extends MeshInstance3D

@onready var main = get_node("/root/Main")# or get_node("/root/main")
@onready var floors_and_tiles_regions = get_node("/root/Main/FloorsAndTileManager")
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

		if multiplayer.is_server():
			# If we are the server, call the spawn request function directly.
			main.request_spawn_tile(floor_slot_id)
		else:
			# If we are a client, send the RPC request to the server.
			main.request_spawn_tile.rpc_id(1, floor_slot_id)
	
	elif Input.is_action_just_pressed("left_click") and not Global.is_spawn_tile:
		floors_and_tiles_regions.floor_id_clicked = floor_slot_id
		
		# Handle player movement
		if not Global.is_power_card_active:
			if floor_slot_id in characters_manager.adjacents_array:
				print("player movement ")
				main.current_player_node.move_to(self.global_transform.origin, floor_slot_id)
			else:
				print("Invalid move: Floor %d is not an adjacent tile." % floor_slot_id)


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
