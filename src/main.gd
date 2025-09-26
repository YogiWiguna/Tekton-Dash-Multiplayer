extends Node3D

signal world_build_complete

@export var current_level_id : int = 1
@export var player_scene: PackedScene = preload("res://scenes/player/player_0.tscn")

# Variables for size of arena
var player_number : int = 4 # Default for player number is 4
var default_rows : int = 10 # Default for rows is 10

# Variable for player actions
var player_actions : int = 2

@onready var network_manager = get_node_or_null("/root/NetworkManager")
@onready var floors_and_tiles_manager = $FloorsAndTileManager
@onready var obstacles_manager = $Obstacles
@onready var characters_manager = $CharactersManager
@onready var turn_manager = $TurnManager
@onready var gui = $Gui
@onready var dice = $DiceManager
@onready var round_label = $Gui/RoundLabel

var ready_players = []
var current_game_state = {}
var spawned_players = {}

var current_player_node = null
var current_turn_player_id: int = -1

var start_positions = { 1: 1, 2: 2, 3: 0, 4: 3 }
var initial_state_generated = false

var world_built = false
var game_started: bool = false

var current_round: int = 0
var is_changing_turn: bool = false

# Variables to queue a turn change if it arrives too early.
var queued_turn_id: int = -1
var queued_round: int = -1

func _ready():
	network_manager.game_state_received.connect(receive_game_state)
	network_manager.players_changed.connect(update_player_spawns)
	network_manager.players_changed.connect(_on_main_players_changed)
	
	# Host generates the world state immediately upon entering the scene.
	if multiplayer.is_server() and not initial_state_generated:
		initial_state_generated = true
		var initial_state = {
			"player_number": player_number,
			"default_rows": default_rows,
			"tiles": floors_and_tiles_manager.generate_random_tile_data(),
			"obstacles": obstacles_manager.generate_obstacle_data()
		}
		network_manager.sync_game_state(initial_state)
		# Host builds its own world from the generated state.
		receive_game_state(initial_state)

func _process(delta):
	if multiplayer.is_server() and world_built and game_started:
		# Check if a turn should end AND we aren't already in the middle of changing turns.
		if player_actions <= 0 and not is_changing_turn:
			# 1. Set the flag immediately to prevent this from running multiple times.
			is_changing_turn = true
			# 2. Defer the call to wait one frame, allowing network packets to sync.
			turn_manager.call_deferred("start_next_turn")

func _on_main_players_changed(players: Dictionary):
	if not multiplayer.is_server(): return

	var current_player_ids = players.keys()
	var cleaned_ready_players = []
	for player_id in ready_players:
		if player_id in current_player_ids:
			cleaned_ready_players.append(player_id)
	
	if ready_players.size() != cleaned_ready_players.size():
		print("SERVER: A player disconnected. Cleaned the ready list.")
		ready_players = cleaned_ready_players

# ========================================
# ===     MULTIPLAYER TILE SYNC        ===
# ========================================

# --- ACTION MANAGEMENT ---
@rpc("any_peer")
func use_player_action():
	if not multiplayer.is_server(): return
	player_actions -= 1

@rpc("any_peer")
func end_player_turn():
	if not multiplayer.is_server(): return
	player_actions = 0

@rpc("any_peer")
func report_client_is_ready():
	if not multiplayer.is_server(): return
	
	var client_id = multiplayer.get_remote_sender_id()
	if client_id not in ready_players:
		print("SERVER: Player %d has reported READY." % client_id)
		ready_players.append(client_id)
		turn_manager.check_if_all_players_are_ready()

# --- TAKE TILE (STAGE 1: HIDE) ---
@rpc("any_peer")
func request_hide_tile(floor_id: int):
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != 0 and sender_id != current_turn_player_id: return

	var tile_node = floors_and_tiles_manager.tiles_array[floor_id]
	var third_token = tile_node.get_node("token_tile3")
	var second_token = tile_node.get_node("token_tile2")
	var first_token = tile_node.get_node("token_tile")

	var token_to_hide_name = ""
	if third_token.visible: token_to_hide_name = third_token.name
	elif second_token.visible: token_to_hide_name = second_token.name
	elif first_token.visible: token_to_hide_name = first_token.name
	
	if token_to_hide_name != "":
		sync_hide_tile.rpc(floor_id, token_to_hide_name)

@rpc("any_peer", "call_local")
func sync_hide_tile(floor_id: int, token_name: String):
	var token_mesh = floors_and_tiles_manager.tiles_array[floor_id].get_node(token_name)
	token_mesh.hide()

# --- TAKE TILE (STAGE 2: NULLIFY) ---
@rpc("any_peer")
func request_nullify_tile(floor_id: int, token_name: String):
	sync_nullify_tile.rpc(floor_id, token_name)

@rpc("any_peer", "call_local")
func sync_nullify_tile(floor_id: int, token_name: String):
	var token_mesh = floors_and_tiles_manager.tiles_array[floor_id].get_node(token_name)
	token_mesh.set_surface_override_material(0, null)

# --- PUT TILE ---
@rpc("any_peer")
func request_put_tile(floor_id: int, item_id: int, is_hologram: bool):
	var tile_node = floors_and_tiles_manager.tiles_array[floor_id]
	var first_token = tile_node.get_node("token_tile")
	var second_token = tile_node.get_node("token_tile2")
	var third_token = tile_node.get_node("token_tile3")

	var token_to_update_name = ""
	if second_token.visible and floor_id in obstacles_manager.stacks_special_id_array:
		token_to_update_name = third_token.name
	elif first_token.visible and (floor_id in obstacles_manager.stacks_id_array or floor_id in obstacles_manager.stacks_special_id_array):
		token_to_update_name = second_token.name
	elif not first_token.visible:
		token_to_update_name = first_token.name

	var material_path = ""
	if is_hologram:
		material_path = Global.tiles_hologram_surface_material[item_id]
	else:
		material_path = Global.tiles_surface_material[item_id]

	if token_to_update_name != "" and material_path != "":
		sync_put_tile.rpc(floor_id, token_to_update_name, material_path)

@rpc("any_peer", "call_local")
func sync_put_tile(floor_id: int, token_name: String, item_res_path: String):
	var token_mesh = floors_and_tiles_manager.tiles_array[floor_id].get_node(token_name)
	token_mesh.set_surface_override_material(0, load(item_res_path))
	token_mesh.show()

# --- SPAWN TILE ---
@rpc("any_peer")
func request_spawn_tile(clicked_floor_id: int):
	var sender_id = multiplayer.get_remote_sender_id()
	print("SERVER: Received spawn request from Player %d for floor %d" % [sender_id, clicked_floor_id])
	
	# --- 1. The Server's Authoritative Roll ---
	# It now calls the new function that ONLY generates a number.
	var authoritative_dice_result = dice.generate_random_result()
	
	# --- (The rest of the logic remains the same) ---
	var floor_to_place_on_id = clicked_floor_id
	if authoritative_dice_result == 2:
		floor_to_place_on_id = current_player_node.current_player_floor_id

	var clicked_tile_node = floors_and_tiles_manager.tiles_array[clicked_floor_id]
	var obstacle_mesh = clicked_tile_node.get_node("obstacle_tile")
	var spawn_type = obstacle_mesh.get_surface_override_material(0).resource_name
	
	var specific_tile_material = _get_specific_tile_material_for_spawn(spawn_type, authoritative_dice_result)

	# --- 2. Broadcast the Authoritative Roll to All Players for Animation ---
	sync_show_dice_roll.rpc(authoritative_dice_result)
	
	# --- 3. Wait for the Animation to play ---
	await get_tree().create_timer(2.0).timeout
	
	# --- 4. Broadcast the Final Tile Placement ---
	if authoritative_dice_result != 5 and specific_tile_material:
		sync_place_spawned_tile.rpc(floor_to_place_on_id, specific_tile_material.resource_path)
	
	# --- 5. Finalize the Action ---
	_set_variables_after_spawn()


@rpc("any_peer", "call_local")
func sync_spawn_tile(floor_id: int, new_material_path: String):
	# All clients receive this message and perform the same simple visual update.
	var token_tile = floors_and_tiles_manager.tiles_array[floor_id].get_node("token_tile")
	token_tile.set_surface_override_material(0, load(new_material_path))
	token_tile.show()


# --- HELPER FUNCTIONS (Copy these into main.gd) ---
func _get_specific_tile_material_for_spawn(spawn_type: String, dice_result: int) -> Material:
	var is_hologram = (dice_result == 3 or dice_result == 4)

	# Handle simple cases first
	if spawn_type == "star_tile_spawn":
		return Global.star_hologram_tile_surface_mat if is_hologram else Global.star_tile_surface_mat
	if spawn_type == "diamond_tile_spawn":
		return Global.diamond_hologram_tile_surface_mat if is_hologram else Global.diamond_tile_surface_mat
	if spawn_type == "heart_tile_spawn":
		return Global.heart_hologram_tile_surface_mat if is_hologram else Global.heart_tile_surface_mat
	if spawn_type == "coin_tile_spawn":
		return Global.coin_hologram_tile_surface_mat if is_hologram else Global.coin_tile_surface_mat

	# Handle the random choice cases. Only the server runs this part.
	if spawn_type == "coin_and_heart_tile_spawn":
		var choice = randi_range(0, 1) # Server's random choice
		if choice == 0: # Coin
			return Global.coin_hologram_tile_surface_mat if is_hologram else Global.coin_tile_surface_mat
		else: # Heart
			return Global.heart_hologram_tile_surface_mat if is_hologram else Global.heart_tile_surface_mat
			
	if spawn_type == "diamond_and_star_tile_spawn":
		var choice = randi_range(0, 1) # Server's random choice
		if choice == 0: # Diamond
			return Global.diamond_hologram_tile_surface_mat if is_hologram else Global.diamond_tile_surface_mat
		else: # Star
			return Global.star_hologram_tile_surface_mat if is_hologram else Global.star_tile_surface_mat

	return null

@rpc("any_peer", "call_local")
func sync_show_dice_roll(result: int):
	# This broadcast now calls the new animation-only function on all clients.
	dice.play_animation_for_result(result)

@rpc("any_peer", "call_local")
func sync_place_spawned_tile(floor_id: int, new_material_path: String):
	# This is the old sync_spawn_tile function, renamed.
	var token_tile = floors_and_tiles_manager.tiles_array[floor_id].get_node("token_tile")
	token_tile.set_surface_override_material(0, load(new_material_path))
	token_tile.show()

@rpc("any_peer", "call_local")
func sync_ui_after_spawn():
	# This broadcast tells all clients to clean up their UI.
	# It calls the function that is now in our new gui.gd script.
	gui.unhover_spawn_tile()

func _set_variables_after_spawn():
	# This logic runs on the server after a spawn action.
	use_player_action()
	sync_reset_spawn_state.rpc()
	
	# After handling the state, send a broadcast to all clients to update their UI.
	sync_ui_after_spawn.rpc()

@rpc("any_peer", "call_local")
func sync_reset_spawn_state():
	# This is a broadcast message from the server to all clients.
	# When a client receives this, it knows the spawn action is complete.
	Global.is_spawn_tile = false

func _choose_hologram_or_common_tiles(dice_result: int, tiles_hologram, tiles_common):
	var tile_chosen
	match dice_result:
		1, 6, 2:
			tile_chosen = tiles_common
		3, 4:
			tile_chosen = tiles_hologram
	return tile_chosen

# Note: The _get_tile_data_for_spawn function you already have in main.gd is correct.
# Ensure it is named _get_tile_data_for_spawn to avoid conflicts.
func _get_tile_data_for_spawn(spawn_type):
	var random_id = randi_range(0,1)
	match spawn_type:
		"star_tile_spawn":
			return {"hologram": Global.star_hologram_tile_surface_mat, "common": Global.star_tile_surface_mat}
		"diamond_tile_spawn":
			return {"hologram": Global.diamond_hologram_tile_surface_mat, "common": Global.diamond_tile_surface_mat}
		"heart_tile_spawn":
			return {"hologram": Global.heart_hologram_tile_surface_mat, "common": Global.heart_tile_surface_mat}
		"coin_tile_spawn":
			return {"hologram": Global.coin_hologram_tile_surface_mat, "common": Global.coin_tile_surface_mat}
		"coin_and_heart_tile_spawn":
			if random_id == 0: return {"hologram": Global.coin_hologram_tile_surface_mat, "common": Global.coin_tile_surface_mat}
			else: return {"hologram": Global.heart_hologram_tile_surface_mat, "common": Global.heart_tile_surface_mat}
		"diamond_and_star_tile_spawn":
			if random_id == 0: return {"hologram": Global.diamond_hologram_tile_surface_mat, "common": Global.diamond_tile_surface_mat}
			else: return {"hologram": Global.star_hologram_tile_surface_mat, "common": Global.star_tile_surface_mat}
	return null


# ========================================
# ===      EXISTING FUNCTIONS          ===
# ========================================

@rpc("any_peer", "call_local")
func set_current_turn_globally(player_id: int, new_round: int):
	if not world_built: return
	
	game_started = true
	current_round = new_round
	round_label.text = "Round: %d" % current_round
	
	current_turn_player_id = player_id
	
	if spawned_players.has(player_id):
		current_player_node = spawned_players[player_id]
		player_actions = 2
		
		# 3. Reset the flag now that the new turn is officially starting.
		if multiplayer.is_server():
			is_changing_turn = false
		
		characters_manager.update_valid_moves(current_player_node)
		current_player_node.start_turn()
		print("--- Round %d | It is now Player %d's turn. ---" % [current_round, player_id])
	else:
		print("Error: Could not find player with ID %d to start turn." % player_id)
		if multiplayer.is_server():
			is_changing_turn = false
	
	if multiplayer.get_unique_id() != player_id:
		characters_manager.adjacents_array.clear()
		characters_manager.occupied_adjacents_array.clear()
		floors_and_tiles_manager.unhover_adjacents_floor()

func receive_game_state(state: Dictionary):
	if world_built: return # Prevent rebuilding the world
	
	print("Applying game state...")
	await floors_and_tiles_manager.build_from_data(state)
	obstacles_manager.build_from_data(state)
	world_built = true
	world_build_complete.emit()
	
	update_player_spawns(network_manager.players)
	
	if queued_turn_id != -1:
		set_current_turn_globally(queued_turn_id, queued_round)
		queued_turn_id = -1
		queued_round = -1

func _on_world_build_complete():
	if queued_turn_id != -1:
		set_current_turn_globally(queued_turn_id, queued_round)
		queued_turn_id = -1
		queued_round = -1

@rpc("any_peer", "call_local")
func update_floor_occupancy(floor_id: int, player_id: int):
	if not is_instance_valid(floors_and_tiles_manager) or floor_id < 0 or floor_id >= floors_and_tiles_manager.floors_array.size():
		return

	var floor_node = floors_and_tiles_manager.floors_array[floor_id]
	if player_id == -1:
		floor_node.occupied_by_player = null
	elif spawned_players.has(player_id):
		floor_node.occupied_by_player = spawned_players[player_id]

func _on_players_changed(_players):
	if multiplayer.is_server():
		network_manager.sync_game_state(current_game_state)

func setup_and_sync_level():
	var obstacle_data = obstacles_manager.generate_obstacle_data()
	var tile_data = floors_and_tiles_manager.generate_random_tile_data()
	
	var game_state = {
		"obstacles": obstacle_data,
		"tiles": tile_data,
		"player_number": player_number,
		"current_level_id": current_level_id
	}
	
	apply_level_data(game_state)
	
	network_manager.sync_game_state(game_state)

func _on_game_state_received():
	var state = network_manager.game_state
	apply_level_data(state)

func apply_level_data(data):
	if data.has("player_number"):
		self.player_number = data.player_number
	if data.has("current_level_id"):
		self.current_level_id = data.current_level_id

	if data.has("obstacles"):
		obstacles_manager.apply_obstacle_data(data.obstacles)
	if data.has("tiles"):
		floors_and_tiles_manager.apply_random_tile_data(data.tiles)

func update_player_spawns(players_data: Dictionary):
	if not multiplayer.is_server():
		return

	for player_id in spawned_players.keys():
		if not players_data.has(player_id):
			despawn_player_on_clients.rpc(player_id)

	for player_id in players_data:
		if not spawned_players.has(player_id):
			var p_data = players_data[player_id]
			var p_num = p_data.get("player_number", -1)
			var floor_id = start_positions.get(p_num, -1)

			if floor_id != -1 and floor_id < floors_and_tiles_manager.floors_array.size():
				var target_floor = floors_and_tiles_manager.floors_array[floor_id]
				var start_pos = target_floor.global_transform.origin + Vector3(0, 0.5, 0)
				spawn_player_on_clients.rpc(p_data, start_pos, floor_id)

@rpc("any_peer", "call_local")
func set_player_position(player_id: int, position: Vector3):
	if spawned_players.has(player_id):
		var player_node = spawned_players[player_id]
		player_node.global_transform.origin = position
		print("RPC received: Set position for player %d" % player_id)
	else:
		print("RPC warning: Could not find spawned player %d to set position." % player_id)

@rpc("any_peer", "call_local")
func spawn_player_on_clients(p_data: Dictionary, position: Vector3, initial_floor_id: int):
	var player_id = p_data["id"]

	if spawned_players.has(player_id):
		return
	
	print("Spawning player %s at floor %d" % [p_data["name"], initial_floor_id])
	var player_instance = player_scene.instantiate()
	player_instance.name = str(player_id)
	
	add_child(player_instance)
	spawned_players[player_id] = player_instance
	
	player_instance.set_multiplayer_authority(player_id)
	player_instance.set_display_name(p_data["name"])
	player_instance.global_transform.origin = position
	player_instance.set_initial_floor(initial_floor_id)

@rpc("any_peer", "call_local")
func despawn_player_on_clients(player_id: int):
	if spawned_players.has(player_id):
		var player_node = spawned_players[player_id]
		if player_node == current_player_node:
			current_player_node = null
		player_node.queue_free()
		spawned_players.erase(player_id)
