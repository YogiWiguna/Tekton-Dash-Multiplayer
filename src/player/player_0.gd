# file: src/player/player_0.gd

extends CharacterBody3D

var current_player_floor_id: int = -1
var _target_floor_id: int = -1

# For manual RPC syncing
var _network_position := Vector3.ZERO
var _network_rotation := Vector3.ZERO

@onready var player_mesh = $PlayerMesh
@onready var player_name = $PlayerName
@onready var main = get_node("/root/Main")
@onready var astar_map = get_node("/root/Main/AstarMap")
@onready var characters_manager = get_node("/root/Main/CharactersManager")

var move_speed: float = 4.0
var path: Array = []
var current_path_index: int = 0

func _physics_process(delta):
	# Code for the player character that THIS machine controls.
	if is_multiplayer_authority():
		# (The authoritative movement logic remains the same)
		if path.is_empty():
			velocity = Vector3.ZERO
			move_and_slide()
		else:
			var target_point = path[current_path_index]
			if global_transform.origin.distance_to(target_point) < 0.1:
				current_path_index += 1
				if current_path_index >= path.size():
					path.clear()
					var old_floor_id = current_player_floor_id
					current_player_floor_id = _target_floor_id
					_target_floor_id = -1

					# Tell all clients to update floor occupancy
					if old_floor_id != -1:
						main.update_floor_occupancy.rpc(old_floor_id, -1) # Set old floor to empty
					if current_player_floor_id != -1:
						main.update_floor_occupancy.rpc(current_player_floor_id, multiplayer.get_unique_id()) # Set new floor to occupied
			
					characters_manager.update_valid_moves(self)
			
			if not path.is_empty():
				var move_direction = global_transform.origin.direction_to(path[current_path_index])
				velocity = move_direction * move_speed
				move_and_slide()
		
		# Periodically send our position to other players.
		update_network_position.rpc(global_transform.origin, global_rotation)

	# Code for ALL OTHER players that are controlled remotely.
	else:
		# Smoothly move (interpolate) towards the last received network position.
		global_transform.origin = global_transform.origin.lerp(_network_position, 0.2)
		global_rotation = global_rotation.slerp(_network_rotation, 0.2)


# This function is called by the authority to start a move.
func move_to(target_position: Vector3, target_floor_id: int):
	if is_multiplayer_authority():
		var positions_path = astar_map.get_tiles_path(global_transform.origin, target_position)
		set_path_for_all_peers.rpc(positions_path, target_floor_id)


# This RPC tells all peers to set up the path for a character's movement.
@rpc("any_peer", "call_local", "reliable")
func set_path_for_all_peers(new_path: Array, new_floor_id: int):
	self.path = new_path
	self.current_path_index = 0
	self._target_floor_id = new_floor_id


# NEW RPC: This is called by the authority to update its state on remote clients.
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
	if player_name:
		player_name.text = new_name
