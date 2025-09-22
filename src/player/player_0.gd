# file: src/player/player_0.gd

extends CharacterBody3D

@onready var player_mesh = $PlayerMesh
@onready var player_name = $PlayerName
@onready var player_collision = $PlayerMesh/StaticBody3D/PlayerCollision
# Get a reference to the AstarMap node to calculate paths
@onready var astar_map = get_node("/root/Main/AstarMap")

# Movement variables
var move_speed: float = 4.0
var path: Array = []
var current_path_index: int = 0
# A flag to check if the player should be controllable, you can set this from your main game script
var is_currently_controlled: bool = true

func _physics_process(delta):
	# If there are no points left in the path, stop moving
	if current_path_index >= path.size():
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Get the next point in the path
	var target_point = path[current_path_index]
	
	# Check if we are close enough to the current target point
	if global_transform.origin.distance_to(target_point) < 0.1:
		current_path_index += 1 # Move to the next point in the path
		# If we've reached the end, stop here
		if current_path_index >= path.size():
			return
	
	# Update the target for this frame
	target_point = path[current_path_index]
	
	# Calculate direction and move towards the target point
	var direction = global_transform.origin.direction_to(target_point)
	velocity = direction * move_speed
	move_and_slide()


## Calculates the path to the target and initiates movement.
func move_to(target_position: Vector3):
	# This function correctly returns an array of Vector3 positions for the path.
	var positions_path = astar_map.get_tiles_path(global_transform.origin, target_position)

	# --- FIX ---
	# The 'positions_path' is already what we need.
	# We can assign it directly to the path variable without looping.
	path = positions_path

	# Reset the path index to start movement from the beginning
	current_path_index = 0

	if path.is_empty():
		print("No valid path found.")
	else:
		print("Path calculated successfully. Player is moving.")
