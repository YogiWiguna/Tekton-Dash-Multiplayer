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
	if is_multiplayer_authority():
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
				return
		
		target_point = path[current_path_index]
		
		var direction = global_transform.origin.direction_to(target_point)
		velocity = direction * move_speed
		move_and_slide()

func move_to(target_position: Vector3):
	# Only the controlling player can calculate a new path.
	if is_multiplayer_authority():
		var positions_path = astar_map.get_tiles_path(global_transform.origin, target_position)
		
		path = positions_path
		
		current_path_index = 0
		
		if path.is_empty():
			print("No valid path found.")
		else:
			print("Path calculated successfully. Player is moving.")

func set_display_name(new_name: String):
	if player_name:
		player_name.text = new_name
