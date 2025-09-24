# file: src/player/player_0.gd

extends CharacterBody3D

@onready var player_mesh = $PlayerMesh
@onready var player_name = $PlayerName
@onready var player_collision = $PlayerMesh/StaticBody3D/PlayerCollision
@onready var astar_map = get_node("/root/Main/AstarMap")

var move_speed: float = 4.0
var path: Array = []
var current_path_index: int = 0
var is_currently_controlled: bool = true

func _physics_process(delta):
	# No changes needed in _physics_process. It correctly follows the 'path' variable.
	if path.is_empty():
		velocity = Vector3.ZERO
		return
	
	if current_path_index >= path.size():
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var target_point = path[current_path_index]
	
	if global_transform.origin.distance_to(target_point) < 0.1:
		current_path_index += 1
		if current_path_index >= path.size():
			path.clear() # Clear the path when movement is complete
			return
	
	if not path.is_empty():
		target_point = path[current_path_index]
		var direction = global_transform.origin.direction_to(target_point)
		velocity = direction * move_speed
		move_and_slide()

func move_to(target_position: Vector3):
	# This function is only called by the player with authority (the one controlling the character).
	if is_multiplayer_authority():
		var positions_path = astar_map.get_tiles_path(global_transform.origin, target_position)
		
		# Instead of just setting the path locally, we now send it to all other players.
		# The 'reliable' flag ensures the message will arrive.
		set_path_for_all_peers.rpc(positions_path)

@rpc("any_peer", "call_local", "reliable")
func set_path_for_all_peers(new_path: Array):
	"""This function is called on all clients (and the host) to set the movement path."""
	self.path = new_path
	self.current_path_index = 0
	
	if new_path.is_empty():
		print("Player %s received an empty path." % name)
	else:
		print("Player %s is moving along a new path with %d points." % [name, new_path.size()])


func set_display_name(new_name: String):
	if player_name:
		player_name.text = new_name
