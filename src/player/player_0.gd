extends CharacterBody3D

var current_player_floor_id: int = -1
var _target_floor_id: int = -1

# For manual RPC syncing
var _network_position := Vector3.ZERO
var _network_rotation := Vector3.ZERO

@onready var main = get_node("/root/Main")
@onready var astar_map = get_node("/root/Main/AstarMap")
@onready var characters_manager = get_node("/root/Main/CharactersManager")
@onready var floors_and_tiles_manager = get_node("/root/Main/FloorsAndTileManager")
@onready var marker_camera = $MarkerCamera
@onready var player_mesh = $PlayerMesh
@onready var player_collision = $PlayerCollision
@onready var player_name = $PlayerName
@onready var float_actions_gui = $float_actions_gui

var move_speed: float = 4.0
var path: Array = []
var current_path_index: int = 0
var is_second_lap: bool = false

var has_moved_this_turn: bool = false
var has_used_action_this_turn: bool = false

func _ready():
	self.connect("input_event", _on_input_event)

func start_turn():
	has_moved_this_turn = false
	has_used_action_this_turn = false
	if is_multiplayer_authority():
		# 1. Recalculate and display the valid movement options.
		characters_manager.update_valid_moves(self)
		
		# 2. Show and update the action buttons (Take, Put, etc.).
		float_actions_gui.call_deferred("show_and_update")

# This function is called when the player's CollisionShape is clicked.
func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if is_multiplayer_authority():
			if main.turn_manager.is_local_players_turn():
				float_actions_gui.visible = not float_actions_gui.visible
				if float_actions_gui.visible:
					float_actions_gui._change_take_icon()

func _physics_process(delta):
	if is_multiplayer_authority():
		if not main.turn_manager.is_local_players_turn() or has_used_action_this_turn:
			float_actions_gui.hide()
		
		if not path.is_empty():
			var target_point = path[current_path_index]
			if global_transform.origin.distance_to(target_point) < 0.1:
				current_path_index += 1
				if current_path_index >= path.size():
					# --- MOVEMENT IS COMPLETE ---
					path.clear()
					
					# Finalize position and update occupancy for all players.
					global_transform.origin = target_point 
					var old_floor_id = current_player_floor_id
					current_player_floor_id = _target_floor_id
					_target_floor_id = -1
					main.update_floor_occupancy.rpc(old_floor_id, -1)
					main.update_floor_occupancy.rpc(current_player_floor_id, get_multiplayer_authority())
					
					# 1. Unhover all the old movement indicators from the board.
					floors_and_tiles_manager.unhover_adjacents_floor()
					
					# 2. Clear the character manager's arrays so it doesn't hold old data.
					characters_manager.adjacents_array.clear()
					characters_manager.occupied_adjacents_array.clear()
					
					# 3. Show the action GUI if the player hasn't already used an action.
					if not has_used_action_this_turn:
						float_actions_gui.show_and_update()

			if not path.is_empty():
				var move_direction = global_transform.origin.direction_to(path[current_path_index])
				velocity = move_direction * move_speed
				move_and_slide()
		else:
			velocity = Vector3.ZERO
			move_and_slide()
		
		update_network_position.rpc(global_transform.origin, global_rotation)
	else:
		global_transform.origin = global_transform.origin.lerp(_network_position, 0.2)
		global_rotation = global_rotation.slerp(_network_rotation, 0.2)


# This function is called by the authority to start a move.
func move_to(target_position: Vector3, target_floor_id: int):
	if not is_multiplayer_authority() or has_moved_this_turn: return
	
	has_moved_this_turn = true
	if multiplayer.get_unique_id() == 1:
		main.use_player_action()
	else:
		main.use_player_action.rpc_id(1)
	float_actions_gui.hide() # Hide GUI during movement.

	var positions_path = astar_map.get_tiles_path(global_transform.origin, target_position)
	set_path_for_all_peers.rpc(positions_path, target_floor_id)

# This RPC tells all peers to set up the path for a character's movement.
@rpc("any_peer", "call_local", "reliable")
func set_path_for_all_peers(new_path: Array, new_floor_id: int):
	self.path = new_path
	self.current_path_index = 0
	self._target_floor_id = new_floor_id


#  This is called by the authority to update its state on remote clients.
@rpc("any_peer", "call_local")
func update_network_position(new_pos: Vector3, new_rot: Vector3):
	_network_position = new_pos
	_network_rotation = new_rot


# (The set_initial_floor and set_display_name functions are unchanged)
func set_initial_floor(floor_id: int):
	current_player_floor_id = floor_id
	# Set initial position for interpolation
	_network_position = global_transform.origin
	_network_rotation = global_rotation
	if is_multiplayer_authority():
		characters_manager.update_valid_moves(self)

func set_display_name(new_name: String):
	$PlayerName.text = new_name

# Safely show the GUI only for the local player
func show_float_gui():
	if is_multiplayer_authority():
		float_actions_gui.show()
		# Update button icons and states when showing
		float_actions_gui._change_take_icon()

# Safely hide the GUI
func hide_float_gui():
	if is_multiplayer_authority():
		float_actions_gui.hide()
