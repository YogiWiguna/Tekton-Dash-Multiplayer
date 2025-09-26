extends Camera3D

# Adjust this value to make the camera follow faster or slower.
@export var smoothness: float = 5.0

# A reference to the main game node, which manages the current player.
@onready var main = get_node("/root/Main")

# This will store the initial distance and orientation from the player.
var _offset: Vector3
var _is_offset_initialized: bool = false
# This will hold a reference to the player character controlled by this client.
var _local_player_node: Node3D = null

# This function searches for the player node controlled by the local machine.
func _find_local_player() -> void:
	# Don't search if we already have a reference.
	if is_instance_valid(_local_player_node):
		return

	# Iterate through all spawned players managed by the main scene.
	for player_id in main.spawned_players:
		var player = main.spawned_players[player_id]
		# is_multiplayer_authority() returns true only for the node
		# controlled by this instance of the game.
		if player.is_multiplayer_authority():
			_local_player_node = player
			# Once found, we don't need to keep searching.
			break

func _process(delta: float) -> void:
	# If we haven't found the local player yet, try to find them.
	# This is necessary because players might not be spawned immediately.
	if not is_instance_valid(_local_player_node):
		_find_local_player()
		# If we still can't find the player, exit the function for this frame.
		if not is_instance_valid(_local_player_node):
			return

	# --- Initialize Offset ---
	# On the first frame with a valid player, calculate and store the initial
	# distance between the camera and that player. This offset will be maintained.
	if not _is_offset_initialized:
		_offset = global_transform.origin - _local_player_node.global_transform.origin
		_is_offset_initialized = true

	# --- Follow Logic ---
	# Calculate the camera's target position by adding the stored offset
	# to the local player's current position.
	var target_position = _local_player_node.global_transform.origin + _offset

	# Smoothly move the camera towards the target position. This keeps the camera
	# at a consistent distance from the player while following their movement.
	# The camera's rotation will remain fixed based on its initial orientation.
	global_transform.origin = global_transform.origin.lerp(target_position, delta * smoothness)
