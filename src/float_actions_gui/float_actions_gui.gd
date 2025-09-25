extends Control

@export var gui_element: Control  # The GUI element to be snapped
@export var target_node: Node3D  # The 3D node to snap to

@onready var main = get_node("/root/Main")
@onready var floors_and_tiles_regions = get_node("/root/Main/FloorsAndTileManager")
@onready var player_board = get_node("/root/Main/Gui/PlayerBoard")
@onready var obstacles = get_node("/root/Main/obstacles")
#@onready var power_card = get_node("/root/Main/gui/power_card")
@onready var gui = get_node("/root/Main/Gui")
#@onready var dice = get_node("/root/Main/DiceManager")
@onready var take_tile_button = $float_gui_container/take_tile_button
@onready var put_tile_button = $float_gui_container/put_tile_button
@onready var spawn_tile_button = $float_gui_container/spawn_tile_button
@onready var do_nothing_button = $float_gui_container/do_nothing_button
@onready var player = $".."

var hover_tile = load("res://assets/graphics/tiles/hover_tile_2.png")
var hover_target = load("res://assets/graphics/tiles/hover_target_1.png")

const hover_obstacle_surface_mat = preload("res://assets/materials/hover_obstacle_surface.tres")
const green_surface_mat = preload("res://assets/materials/green_surface.tres")

const coin_obstacle_animation = preload("res://assets/materials/obstacle_animation/coin_obstacle_animation.tres")
const diamond_obstacle_animation = preload("res://assets/materials/obstacle_animation/diamond_obstacle_animation.tres")
const heart_obstacle_animation = preload("res://assets/materials/obstacle_animation/heart_obstacle_animation.tres")
const star_obstacle_animation = preload("res://assets/materials/obstacle_animation/star_obstacle_animation.tres")

var BUTTON_STATES = {
	"take_tile": {
		"normal": "res://assets/graphics/actions_gui/action_take_01.png",
		"hover": "res://assets/graphics/actions_gui/action_take_02.png"
	},
	"put_tile": {
		"normal": "res://assets/graphics/actions_gui/action_put_01.png",
		"hover": "res://assets/graphics/actions_gui/action_put_02.png"
	},
	"spawn_tile": {
		"normal": "res://assets/graphics/actions_gui/action_spawn_01.png",
		"hover": "res://assets/graphics/actions_gui/action_spawn_02.png"
	},
	"do_nothing": {
		"normal": "res://assets/graphics/actions_gui/nothing_01.png",
		"hover": "res://assets/graphics/actions_gui/nothing_02.png"
	}
}

const TAKE_TILE_HIGHLIGHT = preload("res://scenes/float_actions_gui/take_tile_highlight.gdshader")
const take_tile_floor_mat = preload("res://assets/meshes/tiles_mesh/take_material.tres")
const put_tile_floor_mat = preload("res://assets/meshes/tiles_mesh/put_material.tres")
const power_up_floor_mat =preload("res://assets/meshes/tiles_mesh/power_up_material.tres")

#region List surface material for take and put tiles
const tiles_surface_material = [
	"res://assets/materials/tiles/heart_tile_surface_mat.tres",
	"res://assets/materials/tiles/star_tile_surface_mat.tres",
	"res://assets/materials/tiles/coin_tile_surface_mat.tres",
	"res://assets/materials/tiles/diamond_tile_surface_mat.tres"
]

const tiles_hologram_surface_material = [
	"res://assets/materials/tiles/heart_hologram_tile_surface_mat.tres",
	"res://assets/materials/tiles/star_hologram_tile_surface_mat.tres",
	"res://assets/materials/tiles/coin_hologram_tile_surface_mat.tres",
	"res://assets/materials/tiles/diamond_hologram_tile_surface_mat.tres"
]
#endregion

var taken_tile_mat

# Variable for token tile 
var first_token_tile
var second_token_tile
var third_token_tile

# Variable Power Card
var is_burn_tile := false
var is_freeze := false
var is_swap_pos := false
var is_move_stack := false
var is_move_tile_spawn := false
var is_move_block := false
var is_move_boost := false
var is_plus_action := false
var is_move_racer := false
var is_put_away := false
var is_put_back := false
var is_swap_tiles := false
var is_book_tiles := false

# Variable for max tiles on pb
var normal_count = {
	"diamond" : 0, 
	"star" : 0, 
	"heart" : 0, 
	"coin" : 0
	}
var hologram_count = 0


func _ready():
	connect_button_signals()
	_center_button_pivots()
	
	# Need to wait for buttons to be fully initialized with their textures
	# so they have their correct size
	call_deferred("_setup_button_positions")

#
func _process(_delta):
	# GUARD: Only process if the GUI is visible and there's an active player turn.
	if not visible or not is_instance_valid(main.current_player_node):
		return
	
	snap_gui_to_3d_position()
	_disabled_button()
	_do_nothing_button()


# ========================================
# ===              Signal              ===
# ========================================
func connect_button_signals():
	_connect_button(take_tile_button, "take_tile")
	_connect_button(put_tile_button, "put_tile")
	_connect_button(spawn_tile_button, "spawn_tile")
	_connect_button(do_nothing_button, "do_nothing")
	take_tile_button.connect("pressed", _on_take_tile_button)
	put_tile_button.connect("pressed", _on_put_tile_button)
	spawn_tile_button.connect("pressed", _on_spawn_tile_button)
	do_nothing_button.connect("pressed", _on_do_nothing_button)

func _connect_button(button: Control, button_name: String):
	if button:
		button.mouse_entered.connect(func(): _on_button_mouse_entered(button, button_name))
		button.mouse_exited.connect(func(): _on_button_mouse_exited(button, button_name))

func _on_button_mouse_entered(button: Control, button_name: String):
	if button is BaseButton:
		button.icon = load(BUTTON_STATES[button_name]["hover"])
		
		# Store the original size
		var original_size = button.size
		
		# Positions are now the center of the button
		var center_pos = Vector2.ZERO
		# Set the take tile position button
		if button_name == "take_tile":
			center_pos = Vector2(-80, 0)
		# Set the put tile position button
		elif button_name == "put_tile":
			center_pos = Vector2(10, -145) 
		# Set the spawn tile position button
		elif button_name == "spawn_tile":
			center_pos = Vector2(170, -145)
		# Set the do nothing position button
		elif button_name == "do_nothing":
			center_pos = Vector2(290, 0)
		
		# Wait for button to resize with the new icon
		await get_tree().process_frame
		
		# Set position accounting for the size of the button to keep it centered
		button.position = center_pos - (button.size / 2)

func _on_button_mouse_exited(button: Control, button_name: String):
	if button is BaseButton:
		button.icon = load(BUTTON_STATES[button_name]["normal"])
		
		# Store the original size
		var original_size = button.size
		
		# Positions are now the center of the button
		var center_pos = Vector2.ZERO
		# Set the take tile position button
		if button_name == "take_tile":
			center_pos = Vector2(-61.9, 15)
		# Set the put tile position button
		elif button_name == "put_tile":
			center_pos = Vector2(65, -120)  
		# Set the spawn tile position button
		elif button_name == "spawn_tile":
			center_pos = Vector2(200, -120)
		# Set the do nothing position button
		elif button_name == "do_nothing":
			center_pos = Vector2(320, 15)
		
		# Wait for button to resize with the new icon
		await get_tree().process_frame
		
		# Set position accounting for the size of the button to keep it centered
		button.position = center_pos - (button.size / 2)

func _setup_button_positions():
	# Set manual positions for buttons
	# These positions are now the center points of the buttons
	var container = $float_gui_container
	container.manual_positions = {
		"take_tile_button": Vector2(-61.9, 15),
		"put_tile_button": Vector2(40, -120),  
		"spawn_tile_button": Vector2(200, -120),
		"do_nothing_button": Vector2(320, 15)
	}

	# Force update of positions
	container.arrange_children()

func _do_nothing_button():
	do_nothing_button.disabled = false 

func _on_do_nothing_button():
	if not main.turn_manager.is_local_players_turn(): return

	print("Player chose to do nothing, ending turn.")
	hide()
	
	# Tell the host to end the turn immediately.
	if multiplayer.is_server():
		main.end_player_turn()
	else:
		main.end_player_turn.rpc_id(1)


func _change_take_icon():
	checking_tiles_on_player_pos(player.current_player_floor_id)
	if first_token_tile.visible != false:
		var tile = floors_and_tiles_regions.tiles_array[player.current_player_floor_id]
		# Check if the third token is visible (Player will take the most top)
		if third_token_tile.visible == true:
			var third_token_tile_res_name = third_token_tile.get_surface_override_material(0).resource_name
			if third_token_tile_res_name in Global.tiles_hologram_name:
				_take_tile_icon_change(true)
			else:
				_take_tile_icon_change(false)
		elif second_token_tile.visible == true:
			var second_token_tile_res_name = second_token_tile.get_surface_override_material(0).resource_name
			if second_token_tile_res_name in Global.tiles_hologram_name:
				_take_tile_icon_change(true)
			else:
				_take_tile_icon_change(false)
		else:
			var first_token_tile_res_name = first_token_tile.get_surface_override_material(0).resource_name
			if first_token_tile_res_name in Global.tiles_hologram_name:
				_take_tile_icon_change(true)
			else:
				_take_tile_icon_change(false)

func _take_tile_icon_change(_status):
	# Change the take tile icon 
	if _status:
		## Change the icon for hologram here
		#BUTTON_STATES["take_tile"]["normal"] = "res://assets/graphics/actions_gui/action_put_01.png"
		#BUTTON_STATES["take_tile"]["hover"] = "res://assets/graphics/actions_gui/action_put_02.png"
		
		# Get or create a shader material
		var material = take_tile_button.material
		if not material is ShaderMaterial:
			material = ShaderMaterial.new()
			take_tile_button.material = material
		
		# Apply the shader
		material.shader = TAKE_TILE_HIGHLIGHT
	else:
		#BUTTON_STATES["take_tile"]["normal"] = "res://assets/graphics/actions_gui/action_take_01.png"
		#BUTTON_STATES["take_tile"]["hover"] = "res://assets/graphics/actions_gui/action_take_02.png"
		
		# Remove the shader but keep the material if it exists
		if take_tile_button.material is ShaderMaterial:
			take_tile_button.material.shader = null
	
	take_tile_button.icon = load(BUTTON_STATES["take_tile"]["normal"])


# ========================================
# ===        Helper Function           ===
# ========================================
func _center_button_pivots():
	# Get all buttons
	var buttons = [
		take_tile_button,
		put_tile_button, 
		spawn_tile_button,
		$float_gui_container/do_nothing_button
	]
	
	# Set anchors and pivot for each button
	for button in buttons:
		# Set anchors to center
		button.anchor_left = 0.5
		button.anchor_top = 0.5
		button.anchor_right = 0.5
		button.anchor_bottom = 0.5
		
		# Set grow directions
		button.grow_horizontal = Control.GROW_DIRECTION_BOTH
		button.grow_vertical = Control.GROW_DIRECTION_BOTH
		
		# Ensure button is properly centered
		button.pivot_offset = button.size / 2


func checking_tiles_on_player_pos(_tiles_id):
	first_token_tile = floors_and_tiles_regions.tiles_array[_tiles_id].get_node("token_tile")
	second_token_tile = floors_and_tiles_regions.tiles_array[_tiles_id].get_node("token_tile2")
	third_token_tile = floors_and_tiles_regions.tiles_array[_tiles_id].get_node("token_tile3")

func _reset_player_board_max_tiles_count():
	normal_count = {
		"diamond" : 0, 
		"star" : 0, 
		"heart" : 0, 
		"coin" : 0
		}
	
	hologram_count = 0

func recount_max_tiles_on_player_board():
	# Reset counters before recounting
	_reset_player_board_max_tiles_count()
	
	var _pb_inventory = player_board.inventory
	
	# Count all items in inventory
	for _item_tiles in _pb_inventory:
		if _item_tiles != null:
			var item_name = _item_tiles.item_name
			if "_hologram" in item_name:
				hologram_count += 1
			else:
				if item_name in normal_count:
					normal_count[item_name] += 1
				else:
					normal_count[item_name] = 1
	
	print("normal counts : ", normal_count)
	print("hologram counts: ", hologram_count)

# Check the player location, if it's on boost obstacle then emit the signal after choose the action 
func check_action_if_player_on_boost_obstacle():
	# Emit signal so the player can go to the target floor after do an action
	main.current_player_node.is_player_already_choose.emit()


# Disabled take tile if each of normal tile is reaching 4 (maximum)
# also with the power up tiles 
func _disabled_button():
	var current_player_node = main.current_player_node
	
	# Start and Finish position
	var start_and_finish_row = [0,1,2,3,36,37,38,39]
	if current_player_node.current_player_floor_id in start_and_finish_row:
		take_tile_button.disabled = true
		put_tile_button.disabled = true
	
	var _token_tile_mesh = checking_available_tile()

	# Book tiles
	if _token_tile_mesh.booked_tile_player_id == -1 and hologram_count < 4:
		take_tile_button.disabled = false
	elif _token_tile_mesh.booked_tile_player_id != current_player_node.player_id:
		take_tile_button.disabled = true
	
	if _token_tile_mesh.get_surface_override_material(0) == null:
		return true

	#recount_max_tiles_on_player_board()
	var _resource_name_of_taken_tile = _token_tile_mesh.get_surface_override_material(0).resource_name
	#print("resource name taken tile: ", _resource_name_of_taken_tile)
	
	if "_hologram" in _resource_name_of_taken_tile:
		# Check if the hologram count is more than 4 and resource name is hologram
		if hologram_count >= 4 and _resource_name_of_taken_tile in Global.tiles_hologram_name:
			print("hologram take tile")
			take_tile_button.disabled = true
			return
	else:
		if normal_count[_resource_name_of_taken_tile] >= 4 and _resource_name_of_taken_tile in Global.tiles_name:
			take_tile_button.disabled = true
			return

func snap_gui_to_3d_position():
	if not gui_element or not target_node:
		return
	
	# Get the camera
	var camera = get_viewport().get_camera_3d()
	if not camera:
		print("No camera found in the scene.")
		return
	
	# Get the 3D position of the target node
	var world_position = target_node.global_transform.origin
	#print("world pos : ", world_position)
	# Convert 3D position to 2D screen position
	var screen_position = camera.unproject_position(world_position)
	
	# Check if the point is behind the camera
	if camera.is_position_behind(world_position):
		gui_element.hide()
	else:
		#gui_element.show()
		# Set the GUI element's position
		#print("GUI Element: ",gui_element.position)
		#print("GUI screen pos: ",screen_position)
		
		gui_element.global_position = screen_position - gui_element.size / 2
		#print("Gui global pos : ", gui_element.global_position)

# ========================================
# ===            Take Action           ===
# ========================================
func _on_take_tile_button():
	if not main.turn_manager.is_local_players_turn(): return
	if player.has_used_action_this_turn: return
		
	print("Take tile")
	player.has_used_action_this_turn = true # Set the flag
	if multiplayer.get_unique_id() == 1:
		main.use_player_action()
	else:
		main.use_player_action.rpc_id(1)
	#print("Player Current floor id : ", player.current_player_floor_id)
	main.current_player_node.float_actions_gui.hide()
	var current_player = main.current_player_node
	# Checking tiles on the player position 
	checking_tiles_on_player_pos(player.current_player_floor_id)
	var tile = floors_and_tiles_regions.tiles_array[player.current_player_floor_id]
	var hover_movement_tile = tile.hover_movement_tile
	hover_movement_tile.set_surface_override_material(0, take_tile_floor_mat)
	hover_movement_tile.show()
	
	# Check if the third token is visible (Player will take the most top)
	if third_token_tile.visible == true:
		#print("Take 3rd")
		take_tile_and_place_on_player_board(third_token_tile, hover_movement_tile)
	elif second_token_tile.visible == true:
		#print("Take 2nd")
		take_tile_and_place_on_player_board(second_token_tile, hover_movement_tile)
	else:
		#print("Take 1st")
		take_tile_and_place_on_player_board(first_token_tile, hover_movement_tile)


func take_tile_and_place_on_player_board(_token_tile_mesh, _hover_movement_tile):
	var tile_node = _token_tile_mesh.get_parent()
	# Set material
	taken_tile_mat = _token_tile_mesh.get_surface_override_material(0)

	var resource_name_of_taken_tile = taken_tile_mat.resource_name
	#print("take resource name : ", resource_name_of_taken_tile)
	var _id_taken_tile = Global.tiles_name.find(resource_name_of_taken_tile)
	
	# Animation Take Tile
	_token_tile_mesh.hide()
	# Tekton custom animation 
	var _player = get_parent()

	# Check if the current grab is hologram tiles
	if resource_name_of_taken_tile in Global.tiles_hologram_name:
		_id_taken_tile = Global.tiles_hologram_name.find(resource_name_of_taken_tile)
		#print("id taken tile : ", _id_taken_tile)
		player_board.is_hologram_item = true
		print("player hologram : ", player_board.is_hologram_item)
	
	await get_tree().create_timer(1.0).timeout
	
	## Spawn the item (tiles) into the player board 
	player_board.summon_item(_id_taken_tile)

	# Await for deselected after place the tile
	await player_board.item_grab_succes
	
	# Set the tiles on floor into null (like delete the tiles)
	_token_tile_mesh.set_surface_override_material(0,null)
	_token_tile_mesh.position = Vector3(0,0,0)
	_token_tile_mesh.rotation_degrees = Vector3(0,0,0)
	
	# update the player_board gui
	#gui.change_turn()
	
	print("selected slot pb: ", player_board.selected_slot)
	print("player hologram : ", player_board.is_hologram_item)
	# We need to check if the hologram tiles is taken and also check 
	if player_board.is_hologram_item :
		print("Hologram grabbed")
		player_board.is_hologram_item = false
		if Global.current_round >= 3:
			_hover_movement_tile.set_surface_override_material(0, power_up_floor_mat)
			print('acive')
			#power_card_active()
			#await Global.power_card_active

	#await get_tree().create_timer(2.0).timeout
	if Global.sabotage_meter_update:
		Global.sabotage_meter_update = false
		var sabotage_meter = gui.sabotage_meter
		var _player_id = main.current_player_node.player_id
		sabotage_meter._sabotage_meter_update_value(_player_id)

	# Substract the player actions because the grab is succed
	#main.player_actions -= 1
	Global.is_action_done = true
	Global.is_power_card_active = false
	# Check the action, if player on a boost obstacle
	#check_action_if_player_on_boost_obstacle()
	# Update max tiles on player board
	recount_max_tiles_on_player_board()
	# Set float gui after choose the action button
	#if !main.current_player_node.is_player_clicked:
		#main.current_player_node.show_float_gui()

# ========================================
# ===            Put Action            ===
# ========================================
func _on_put_tile_button():
	if not main.turn_manager.is_local_players_turn(): return
	if player.has_used_action_this_turn: return
	
	print("Put tile")
	#print("Player Current floor id : ", player.current_player_floor_id)
	player.has_used_action_this_turn = true
	main.use_player_action.rpc_id(1)
	main.current_player_node.float_actions_gui.hide()
	checking_tiles_on_player_pos(player.current_player_floor_id)
	# Deselect the selected inventory 
	player_board.deselect_slot()
	var tile = floors_and_tiles_regions.tiles_array[player.current_player_floor_id]
	var hover_movement_tile = tile.hover_movement_tile
	hover_movement_tile.set_surface_override_material(0,put_tile_floor_mat)
	hover_movement_tile.show()
	# Checking where's the player should put the tiles
	if second_token_tile.visible == true:
		#print("put the third token with special stack ")
		if player.current_player_floor_id in obstacles.stacks_special_id_array :
			put_tile_on_current_player_pos(third_token_tile, hover_movement_tile)
	elif first_token_tile.visible == true:
		#print("put the second token with stack")
		if player.current_player_floor_id in obstacles.stacks_id_array or player.current_player_floor_id in obstacles.stacks_special_id_array :
			put_tile_on_current_player_pos(second_token_tile, hover_movement_tile)
	elif first_token_tile.visible == false:
		#print("put the first token without stack")
		put_tile_on_current_player_pos(first_token_tile, hover_movement_tile)

func put_tile_on_current_player_pos(_token_tile_mesh, _hover_movement_tile):
	var tile_node = _token_tile_mesh.get_parent()
	player_board.is_put_item = true
	
	# Await for deselected after choose the tile
	await player_board.item_put_succes
	
	#_token_tile_mesh.scale = Vector3(0,0,0)
	
	#main.current_player_node.animation_player.play("drop_tile_2")
	
	# Get the id for current selected_slot from inventory 
	var _selected_slot = player_board.id_for_put_tiles
	# Get the item_id from current selected slot 
	var id_from_selected_tiles_on_pb = player_board.inventory[_selected_slot].item_id
	# Set the texture tiles on current player floor based on selected tiles
	#print("put material : ",tiles_surface_material[id_from_selected_tiles_on_pb])
	var _material = load(tiles_surface_material[id_from_selected_tiles_on_pb])

	# Check if the hologram is the choosen one
	if player_board.is_hologram_item:
		#print("put hologram")
		# Set the texture tiles on current player floor based on selected tiles
		_material = load(tiles_hologram_surface_material[id_from_selected_tiles_on_pb])
		player_board.is_hologram_item = false
	#print("material : ", _material)

	#player.players_meshes.tiles.set_surface_override_material(0,_material)
	#main.current_player_node.animation_player.play("animation-pack/drop_tile_1")
	await get_tree().create_timer(3.5).timeout

	# pb = player board
	# Recount the tiles on the pb
	recount_max_tiles_on_player_board()

	# Set the surface material for token tile mesh we gonna put in the arena or main
	#player.players_meshes.tiles.hide()
	_token_tile_mesh.set_surface_override_material(0, _material)
	_token_tile_mesh.show()
	print("token tile mesh show")

	# Animation for put tile
	#if _token_tile_mesh.name == "token_tile":
		#tile_node.animation_player.play("put_token_tile")
	#elif _token_tile_mesh.name == "token_tile2":
		#tile_node.animation_player.play("put_token_tile_2")
	#elif _token_tile_mesh.name == "token_tile3":
		#tile_node.animation_player.play("put_token_tile_3")
	
	await get_tree().create_timer(1.0).timeout
	# Substract the player actions because the put is succed
	#main.player_actions -= 1
	Global.is_action_done = true
	_hover_movement_tile.hide()

	# Check the action, if player on a boost obstacle
	#check_action_if_player_on_boost_obstacle()
	# Set float gui after choose the action button
	#if !main.current_player_node.is_player_clicked:
		#main.current_player_node.show_float_gui()

# ========================================
# ===          Spawn Action            ===
# ========================================
func _on_spawn_tile_button():
	if not main.turn_manager.is_local_players_turn(): return
	if player.has_used_action_this_turn: return
	
	player.has_used_action_this_turn = true
	# Tell the host we used an action.
	main.use_player_action.rpc_id(1)
	print("spawn tiles")
	main.current_camera.set_priority(0)
	main.camera_tactic.set_priority(10)
	
	# Set the is_spawn_tile into true
	Global.is_spawn_tile = true
	Global.is_action_done = true
	# Hide player board
	gui.show_or_hide_for_spawn_tile(false)
	
	# hide the float action gui
	main.current_player_node.float_actions_gui.hide()
	
	# Hover tiles 
	hover_tiles_for_spawn_tile_action()

func hover_tiles_for_spawn_tile_action():
	for _id in obstacles.tiles_spawn_id_array:
		var obstacle_tile = floors_and_tiles_regions.tiles_array[_id].get_node("obstacle_tile")
		var obstacle_tile_animation = floors_and_tiles_regions.tiles_array[_id].get_node("obstacle_tile_animation")
		
		# Set the scale and UV for the obstacle tile 
		obstacle_tile.scale = Vector3(1.1 ,1.1 ,1.1)
		obstacle_tile.get_surface_override_material(0).set_uv1_scale(Vector3(0.85,0.85,0.85))
		obstacle_tile.get_surface_override_material(0).set_uv1_offset(Vector3(0.075,0.075,0))
		
		# Set the colors of the Shaders of obstacle_tile_animation
		# Coin Tile
		if _id == obstacles.tiles_spawn_id_array[0]:
			obstacle_tile_animation.set_surface_override_material(0, coin_obstacle_animation)
		# Diamond Tile
		elif _id == obstacles.tiles_spawn_id_array[1] :
			obstacle_tile_animation.set_surface_override_material(0, diamond_obstacle_animation)
		# Star Tile
		elif _id == obstacles.tiles_spawn_id_array[2] :
			obstacle_tile_animation.set_surface_override_material(0, star_obstacle_animation)
		# Heart Tile
		elif _id == obstacles.tiles_spawn_id_array[3] :
			obstacle_tile_animation.set_surface_override_material(0, heart_obstacle_animation)
		obstacle_tile_animation.show()

func unhover_spawn_tile():
	var hover_movement_mesh
	for _id in obstacles.tiles_spawn_id_array:
		var obstacle_tile = floors_and_tiles_regions.tiles_array[_id].get_node("obstacle_tile")
		var obstacle_tile_animation = floors_and_tiles_regions.tiles_array[_id].get_node("obstacle_tile_animation")
		
		obstacle_tile.scale = Vector3(1.24, 1.24, 1.24)
		obstacle_tile.get_surface_override_material(0).set_uv1_scale(Vector3(1,1,1))
		obstacle_tile.get_surface_override_material(0).set_uv1_offset(Vector3(0,0,0))
		
		hover_movement_mesh = floors_and_tiles_regions.tiles_array[_id].get_node("hover_movement_tile")
		hover_movement_mesh.hide()
		obstacle_tile_animation.hide()


# ========================================
# ===           Power Card             ===
# ========================================


func checking_available_tile():
	# Get the tiles mesh on the current place
	checking_tiles_on_player_pos(player.current_player_floor_id)
	var _token_tile_mesh 
	# Check if the third token is visible (Player will take the most top)
	if third_token_tile.visible == true:
		#print("Take 3rd")
		_token_tile_mesh = third_token_tile
	elif second_token_tile.visible == true:
		#print("Take 2nd")
		_token_tile_mesh = second_token_tile
	else:
		#print("Take 1st")
		_token_tile_mesh = first_token_tile
	
	return _token_tile_mesh

#func show_pop_up_window(_text: String):
	#var pop_up_window_pc = power_card.pop_up_window
	#var label_pop_up_window = pop_up_window_pc.label
	#label_pop_up_window.text = _text
	#pop_up_window_pc.show()


func set_tekton_sabotage_animation():
	if main.is_player_2_turn:
		gui.tekton_animation.show()
		gui.tekton_animation.play("copper_jr_sabotage")

func set_tekton_idle_animation():
	if main.is_player_2_turn:
		gui.tekton_animation.show()
		gui.tekton_animation.play("copper_jr_idle")

func checking_level_array(level_occ_id_array):
	if main.player_number == 4:
		match main.current_level_id:
			0: # Bridge 
				level_occ_id_array = [9,20,31]
			4: # Water 
				level_occ_id_array = [11,35]
	return level_occ_id_array

func hilight_material_for_power_card(_material):
	var _neighbors_sprite_exist = []
	
	for tiles in floors_and_tiles_regions.tiles_array:
		tiles.hover_tile.texture = hover_target


	# All tiles highlight
	# Burn Tile
	#if is_burn_tile:
		#for _id in range(floors_and_tiles_regions.floors_array.size()):
			#var _first_token_tile = floors_and_tiles_regions.tiles_array[_id].get_node("token_tile")
			##print("surface first token tile : ", _first_token_tile.get_surface_override_material(0))
			#if _first_token_tile.get_surface_override_material(0) != null:
				##Set the Tiles surface material on each Tiles based on the "j" variable into Black material
				#var hover_tiles_show = floors_and_tiles_regions.tiles_array[_id].get_node("hover_movement_tile")
				#hover_tiles_show.show()
				#hover_tiles_show.set_surface_override_material(0,_material)
	#
	## Character highlight
	## Freeze or Swap position or Move Racer
	#if is_freeze or is_swap_pos or is_move_racer:
		#for _id in range(floors_and_tiles_regions.floors_array.size()):
			#if floors_and_tiles_regions.floors_array[_id].occupied_by_player != null :
				#if _id == main.current_player_node.current_player_floor_id:
					#pass
				#else:
					#var hover_tiles_show = floors_and_tiles_regions.tiles_array[_id].get_node("hover_movement_tile")
					#hover_tiles_show.show()
					#hover_tiles_show.set_surface_override_material(0,_material)
	#
	## Move Stack
	#if is_move_stack:
		#if !pc_move_stack.is_item:
			#print("obstacle all stacks ids : ", pc_move_stack.obstacles_all_stacks_ids)
			#for _id in pc_move_stack.obstacles_all_stacks_ids:
				#var hover_tiles_show = floors_and_tiles_regions.tiles_array[_id].get_node("hover_movement_tile")
				#hover_tiles_show.show()
				#hover_tiles_show.set_surface_override_material(0,_material)
		#else:
			#var availabel_floors_arr : Array = []
			#var start_and_finish_ids = []
			#_set_start_and_finish_ids(start_and_finish_ids)
			#
			##print("start and finish ids : ", start_and_finish_ids)
			#for _id in range(floors_and_tiles_regions.floors_array.size()):
				#var obstacle_tile = floors_and_tiles_regions.tiles_array[_id].obstacle_tile
				#if _id in start_and_finish_ids: 
					#continue
				#else:
					#if obstacle_tile.visible == false:
						#availabel_floors_arr.append(_id)
			#
			#
			## Check the restriction floor
			#var bridge_occupied_arr
			#var water_occupied_arr
			## Level floors restriction
			#if main.player_number == 4:
				#match main.current_level_id :
					#0:
						#bridge_occupied_arr = [9,20,31]
						#for _id in bridge_occupied_arr:
							#availabel_floors_arr.erase(_id)
					#4:
						#water_occupied_arr = [11,35]
						#for _id in water_occupied_arr:
							#availabel_floors_arr.erase(_id)
#
			#var floor_id_stack_before = pc_move_stack.floor_choose_id
			#print("floor id stack : ", floor_id_stack_before)
			#if floor_id_stack_before in availabel_floors_arr:
				#availabel_floors_arr.erase(floor_id_stack_before)
#
			#_check_player_position(availabel_floors_arr)
#
			#Global.available_floors_for_move_stack = availabel_floors_arr
			#print("available floor tile array : ", availabel_floors_arr)
			#for _id in availabel_floors_arr:
				#var hover_tiles_show = floors_and_tiles_regions.tiles_array[_id].get_node("hover_movement_tile")
				#hover_tiles_show.show()
				#hover_tiles_show.set_surface_override_material(0,_material)
	#
	## Move Tile Spawn
	#if is_move_tile_spawn:
		#if !pc_move_tile_spawn.is_item:
			#print("obstacle all stacks ids : ", pc_move_tile_spawn.obstacles_all_tile_spawns_ids)
			#for _id in pc_move_tile_spawn.obstacles_all_tile_spawns_ids:
				#var hover_tiles_show = floors_and_tiles_regions.tiles_array[_id].get_node("hover_movement_tile")
				#hover_tiles_show.show()
				#hover_tiles_show.set_surface_override_material(0,_material)
		#else:
			#var availabel_floors_arr : Array = []
			#var start_and_finish_ids = []
			#_set_start_and_finish_ids(start_and_finish_ids)
			#
			##print("start and finish ids : ", start_and_finish_ids)
			#for _id in range(floors_and_tiles_regions.floors_array.size()):
				#var obstacle_tile = floors_and_tiles_regions.tiles_array[_id].obstacle_tile
				#if _id in start_and_finish_ids: 
					#continue
				#else:
					#if obstacle_tile.visible == false:
						#availabel_floors_arr.append(_id)
			#
			#
			## Check the restriction floor
			#var bridge_occupied_arr
			#var water_occupied_arr
			## Level floors restriction
			#if main.player_number == 4:
				#match main.current_level_id :
					#0:
						#bridge_occupied_arr = [9,20,31]
						#for _id in bridge_occupied_arr:
							#availabel_floors_arr.erase(_id)
					#4:
						#water_occupied_arr = [11,35]
						#for _id in water_occupied_arr:
							#availabel_floors_arr.erase(_id)
#
			#var floor_id_tile_spawn_before = pc_move_tile_spawn.floor_choose_id
			#if floor_id_tile_spawn_before in availabel_floors_arr:
				#availabel_floors_arr.erase(floor_id_tile_spawn_before)
#
			#_check_player_position(availabel_floors_arr)
#
			#Global.available_floors_for_move_tile_spawn = availabel_floors_arr
			##print("available floor tile array : ", availabel_floors_arr)
			#for _id in availabel_floors_arr:
				#var hover_tiles_show = floors_and_tiles_regions.tiles_array[_id].get_node("hover_movement_tile")
				#hover_tiles_show.show()
				#hover_tiles_show.set_surface_override_material(0,_material)
	#
	## Move Block
	#if is_move_block:
		#if !pc_move_block.is_item:
			#print("obstacle all stacks ids : ", pc_move_block.obstacles_all_blocks_ids)
			#for _id in pc_move_block.obstacles_all_blocks_ids:
				#var hover_tiles_show = floors_and_tiles_regions.tiles_array[_id].get_node("hover_movement_tile")
				#hover_tiles_show.show()
				#hover_tiles_show.set_surface_override_material(0,_material)
		#else:
			#var availabel_floors_arr : Array = []
			#var start_and_finish_ids = []
			#_set_start_and_finish_ids(start_and_finish_ids)
			#
			##print("start and finish ids : ", start_and_finish_ids)
			#for _id in range(floors_and_tiles_regions.floors_array.size()):
				#var obstacle_tile = floors_and_tiles_regions.tiles_array[_id].obstacle_tile
				#if _id in start_and_finish_ids: 
					#continue
				#else:
					#availabel_floors_arr.append(_id)
			#
			#var floor_id_block_before = pc_move_block.floor_choose_id
			#if floor_id_block_before in availabel_floors_arr:
				#availabel_floors_arr.erase(floor_id_block_before)
			##print("available floors : ", availabel_floors_arr)
			## Check the restriction floor
			#var bridge_occupied_arr
			#var water_occupied_arr
			## Level floors restriction
			#if main.player_number == 4:
				#match main.current_level_id :
					#0:
						#bridge_occupied_arr = [9,20,31]
						#for _id in bridge_occupied_arr:
							#availabel_floors_arr.erase(_id)
					#4:
						#water_occupied_arr = [11,35]
						#for _id in water_occupied_arr:
							#availabel_floors_arr.erase(_id)
			## Invalid last row - 1
			#var invalid_floors = [32,33,34,35]
			#for _id in invalid_floors:
				#availabel_floors_arr.erase(_id)
			#
			#availabel_floors_arr = _check_available_floor_for_block(availabel_floors_arr)
			#
			#Global.available_floors_for_move_block = availabel_floors_arr
			#print("available floor tile array : ", availabel_floors_arr)
			#for _id in availabel_floors_arr:
				#var hover_tiles_show = floors_and_tiles_regions.tiles_array[_id].get_node("hover_movement_tile")
				#hover_tiles_show.show()
				#hover_tiles_show.set_surface_override_material(0,_material)
	#
	## Move Boost
	#if is_move_boost:
		#if !pc_move_boost.is_item:
			#print("obstacle all stacks ids : ", pc_move_boost.obstacles_all_boosts_ids)
			#for _id in pc_move_boost.obstacles_all_boosts_ids:
				#var hover_tiles_show = floors_and_tiles_regions.tiles_array[_id].get_node("hover_movement_tile")
				#hover_tiles_show.show()
				#hover_tiles_show.set_surface_override_material(0,_material)
		#else:
			#var availabel_floors_arr : Array = []
			#var start_and_finish_ids = []
			#_set_start_and_finish_ids(start_and_finish_ids)
			#
			##print("start and finish ids : ", start_and_finish_ids)
			#for _id in range(floors_and_tiles_regions.floors_array.size()):
				#var obstacle_tile = floors_and_tiles_regions.tiles_array[_id].obstacle_tile
				#if _id in start_and_finish_ids: 
					#continue
				#else:
					#if obstacle_tile.visible == false:
						#availabel_floors_arr.append(_id)
			##print("available floors : ", availabel_floors_arr)
			## Check the restriction floor
			#var bridge_occupied_arr
			#var water_occupied_arr
			## Level floors restriction
			#if main.player_number == 4:
				#match main.current_level_id :
					#0:
						#bridge_occupied_arr = [9,20,31]
						#for _id in bridge_occupied_arr:
							#availabel_floors_arr.erase(_id)
					#4:
						#water_occupied_arr = [11,35]
						#for _id in water_occupied_arr:
							#availabel_floors_arr.erase(_id)
				#availabel_floors_arr = _check_available_floor_for_boost(availabel_floors_arr)
			#
			#_check_player_position(availabel_floors_arr)
			#
			#Global.available_floors_for_move_boost = availabel_floors_arr
			#print("available floor tile array : ", availabel_floors_arr)
			#for _id in availabel_floors_arr:
				#var hover_tiles_show = floors_and_tiles_regions.tiles_array[_id].get_node("hover_movement_tile")
				#hover_tiles_show.show()
				#hover_tiles_show.set_surface_override_material(0,_material)

func unhilight_material_for_power_card():
	#print("unhilight pc")
	Global.is_power_card_active = false
	#gui.power_card.animated_sprite.visible = false
	#gui.power_card.animation_contiue()
	for _id in range(floors_and_tiles_regions.floors_array.size()):
		var _first_token_tile = floors_and_tiles_regions.tiles_array[_id].get_node("token_tile")
		#Set the Tiles surface material on each Tiles based on the "j" variable into Black material
		var hover_tiles_show = floors_and_tiles_regions.tiles_array[_id].get_node("hover_movement_tile")
		hover_tiles_show.hide()
		hover_tiles_show.set_surface_override_material(0,null)
	
	for tiles in floors_and_tiles_regions.tiles_array:
		tiles.hover_tile.texture = hover_tile
		tiles.hover_tile.hide()

func _set_start_and_finish_ids(start_and_finish_ids):
	var total_tiles = floors_and_tiles_regions.tiles_array.size()
	for _id in range(main.player_number):
		start_and_finish_ids.append(_id)
		
	var finish_line_ids = []
	for _id in range(total_tiles - main.player_number, total_tiles):
		finish_line_ids.append(_id)
	
	start_and_finish_ids.append_array(finish_line_ids) 
	#print("start and finish ids : ", start_and_finish_ids)
	return start_and_finish_ids

func _check_player_position(_available_floors_ids):
	var player_floors_ids := []

	# Generate player position in the floors
	for _id in range(main.player_number * main.default_rows):
		if floors_and_tiles_regions.floors_array[_id].occupied_by_player != null:
			player_floors_ids.append(_id)

	# Delete the player floor id in available floor ids
	for _id in player_floors_ids:
		_available_floors_ids.erase(_id)
	
	return _available_floors_ids

#region Check Available floor for Block
#func _check_available_floor_for_block(_available_floor):
	## Block
	#var blocks_ids_duplicate = pc_move_block.obstacles_all_blocks_ids
	#var floor_id_block_before = pc_move_block.floor_choose_id
	#var occupied_blocks_ids = []
#
	## Checking the id of choosen block 
	## Delete the choosen floor in available floor
	#if floor_id_block_before in _available_floor:
		#_available_floor.erase(floor_id_block_before)
#
	### IF block Horizontal got grabbed or choosen
	## block_1 is block horizontal
	#if pc_move_block.block_mat.resource_name == "block_1":
		## Checking the floor id , which one of the block horizontal the player choose
		#var block_horizontal_not_choosen_id
		#var occupied_row_block_horizontal = []
		#var occupied_floors_block_vertical = []
#
		## Checking the others block horizontal
		## 0 and 1 index from blocks_ids_dulicate is block horizontal
		#if floor_id_block_before == blocks_ids_duplicate[0]:
			#block_horizontal_not_choosen_id = blocks_ids_duplicate[1] # Second index 
			#occupied_row_block_horizontal = _checking_occupied_block_horizontal_row(block_horizontal_not_choosen_id, occupied_row_block_horizontal)
			#print("occupied row block horizontal : ", occupied_row_block_horizontal)
			#occupied_blocks_ids += occupied_row_block_horizontal
		#else:
			#block_horizontal_not_choosen_id = blocks_ids_duplicate[0] # First index 
			#occupied_row_block_horizontal = _checking_occupied_block_horizontal_row(block_horizontal_not_choosen_id, occupied_row_block_horizontal)
			#print("occupied row block horizontal : ", occupied_row_block_horizontal)
			#occupied_blocks_ids += occupied_row_block_horizontal
		#
		## Checking block vertical occupied floor
		## 2 and 3 index from blocks_ids_dulicate is block vertical
		#var id_block_vertical
		#if main.player_number == 4:
			#for _id in range(2,4):
				#id_block_vertical = blocks_ids_duplicate[_id]
				#occupied_floors_block_vertical += _checking_occupied_block_vertical(id_block_vertical)
#
		## Add the occupied block vertical to occupied blocks ids
		#occupied_blocks_ids += occupied_floors_block_vertical
#
	### IF block Vertical got grabbed or choosen
	## block_2 is block vertical
	#else:
		## Checking the floor id , which one of the block horizontal the player choose
		#var block_vertical_not_choosen_id
		#var occupied_lane_block_vertical = []
		#var occupied_floors_block_horizontal = []
#
		## Checking the others block vertical
		## 0 and 1 index from blocks_ids_dulicate is block vertical
		#if floor_id_block_before == blocks_ids_duplicate[2]:
			#block_vertical_not_choosen_id = blocks_ids_duplicate[3] # Fourth index 
			#occupied_lane_block_vertical = _checking_occupied_block_vertical_lane(block_vertical_not_choosen_id, occupied_lane_block_vertical)
			#print("occupied lane block vertical : ", occupied_lane_block_vertical)
			#occupied_blocks_ids += occupied_lane_block_vertical
		#else:
			#block_vertical_not_choosen_id = blocks_ids_duplicate[2] # Third index 
			#occupied_lane_block_vertical = _checking_occupied_block_vertical_lane(block_vertical_not_choosen_id, occupied_lane_block_vertical)
			#print("occupied lane block vertical : ", occupied_lane_block_vertical)
			#occupied_blocks_ids += occupied_lane_block_vertical
		#
		## Checking block vertical occupied floor
		## 2 and 3 index from blocks_ids_dulicate is block vertical
		#var id_block_horizontal
		#if main.player_number == 4:
			#for _id in range(0,2):
				#id_block_horizontal = blocks_ids_duplicate[_id]
				#occupied_floors_block_horizontal += _checking_occupied_block_horizontal(id_block_horizontal)
#
		## Add the occupied block vertical to occupied blocks ids
		#occupied_blocks_ids += occupied_floors_block_horizontal
#
	### Boost Checking
#
	##print("occupied blocks ids before: ", occupied_blocks_ids)
	## Delete the duplicate id from occupied_blocks_ids
	#occupied_blocks_ids = Array(occupied_blocks_ids.duplicate().reduce(func(acc, item): return acc + [item] if item not in acc else acc, []))
	##print("occupied blocks ids after: ", occupied_blocks_ids)
#
	## Delete the occupied ids from available floor
	#for _occ_id in occupied_blocks_ids:
		#_available_floor.erase(_occ_id)
#
	#return _available_floor

# Checking block horizontal can't be in the same row 
func _checking_occupied_block_horizontal_row(_block_horizontal_not_choosen_id, _occupied_row_block_horizontal):
	if main.player_number == 4:
		match _block_horizontal_not_choosen_id:
			4,5,6,7:
				_occupied_row_block_horizontal = [4,5,6,7]
			8,9,10,11:
				_occupied_row_block_horizontal = [8,9,10,11]
			12,13,14,15:
				_occupied_row_block_horizontal = [12,13,14,15]
			16,17,18,19:
				_occupied_row_block_horizontal = [16,17,18,19]
			20,21,22,23:
				_occupied_row_block_horizontal = [20,21,22,23]
			24,25,26,27:
				_occupied_row_block_horizontal = [24,25,26,27]
			28,29,30,31:
				_occupied_row_block_horizontal = [28,29,30,31]
			32,33,34,35:
				_occupied_row_block_horizontal = [32,33,34,35]
	return _occupied_row_block_horizontal

# Checking occupied block vertical if block horizontal is choose
func _checking_occupied_block_vertical(_id_block_vertical):
	# ibv = id block vertical
	var id_left_ibv = _id_block_vertical - 1
	var id_infront_ibv = _id_block_vertical + main.player_number
	var id_top_left_corner_ibv = id_infront_ibv - 1
	var _occupied_ids = []

	# Add the id to occupied ids array
	_occupied_ids.append(_id_block_vertical)
	_occupied_ids.append(id_left_ibv)
	_occupied_ids.append(id_infront_ibv)
	_occupied_ids.append(id_top_left_corner_ibv)

	return _occupied_ids

# Checking block vertical can't be in the same lane-gap
func _checking_occupied_block_vertical_lane(_block_vertical_not_choosen_id, _occupied_row_block_vertical):
	if main.player_number == 4:
		match _block_vertical_not_choosen_id:
			5,9,13,17,21,25,29,33:
				_occupied_row_block_vertical = [5,9,13,17,21,25,29,33]
			6,10,14,18,22,26,30,34:
				_occupied_row_block_vertical = [6,10,14,18,22,26,30,34]
			7,11,15,19,23,27,31,35:
				_occupied_row_block_vertical = [7,11,15,19,23,27,31,35]
	
	if main.player_number == 4:
		_occupied_row_block_vertical += [4,8,12,16,20,24,28,32]
	return _occupied_row_block_vertical

func _checking_occupied_block_horizontal(_id_block_horizontal):
		# ibv = id block vertical
	var id_right_ibh = _id_block_horizontal + 1
	var id_bottom_ibh = _id_block_horizontal - main.player_number
	var id_bottom_right_corner_ibh = id_bottom_ibh + 1
	var _occupied_ids = []
	var _block_last_lane = [7,11,15,19,23,27,31,35]

	# Add the id to occupied ids array
	if _id_block_horizontal in _block_last_lane:
		_occupied_ids.append(_id_block_horizontal)
		_occupied_ids.append(id_bottom_ibh)
	else:
		_occupied_ids.append(_id_block_horizontal)
		_occupied_ids.append(id_right_ibh)
		_occupied_ids.append(id_bottom_ibh)
		_occupied_ids.append(id_bottom_right_corner_ibh)

	return _occupied_ids
#endregion

# Check Available Floor For BOOST Obstacle
#func _check_available_floor_for_boost(_availabel_floors_arr):
	#var all_boost_ids =  pc_move_boost.obstacles_all_boosts_ids
	#var floor_id_boost_choosen = pc_move_boost.floor_choose_id
	#var occupied_boosts_ids = []
	#var first_lane = [4,8,12,16,20,24,28,32]
	#var last_lane = [7,11,15,19,23,27,31,35]
	#
	## Delete the choosen floor in available floor
	#if floor_id_boost_choosen in _availabel_floors_arr:
		#_availabel_floors_arr.erase(floor_id_boost_choosen)
	#
	### Checking the adjacents of every boost ids except the floor id boost choosen
	#for _id in all_boost_ids:
		## ibc = id boost choosen
		#var id_bottom_ibc = _id - main.player_number
		#var id_left_ibc = _id - 1
		#var id_right_ibc = _id + 1
		#var id_infront_ibc = _id + main.player_number
		#
		## Checking if _id is not the same as the choosen id
		#if _id != floor_id_boost_choosen:
			### Checking wehre is the other boost position
			#if _id in first_lane:
				#occupied_boosts_ids.append(id_bottom_ibc)
				#occupied_boosts_ids.append(id_right_ibc)
				#occupied_boosts_ids.append(id_infront_ibc)
			#elif _id in last_lane:
				#occupied_boosts_ids.append(id_bottom_ibc)
				#occupied_boosts_ids.append(id_left_ibc)
				#occupied_boosts_ids.append(id_infront_ibc)
			#else:
				#occupied_boosts_ids.append(id_bottom_ibc)
				#occupied_boosts_ids.append(id_left_ibc)
				#occupied_boosts_ids.append(id_right_ibc)
				#occupied_boosts_ids.append(id_infront_ibc)
			#occupied_boosts_ids.append(_id)
#
	### Checking every block horizontal
	## Horizontal index 0 and 1, Vertical index 2 and 3
	#var blocks_ids = obstacles.blocks_id_array 
	#
	#for _id in range(0,2):
		#var block_h_id = blocks_ids[_id] # Get the horizontal ids only, index 0 and 1
		## bhi = Block horizontal id
		#var id_right_bhi = block_h_id + 1
		#var id_left_bhi = block_h_id - 1
		#var id_bottom_right_bhi = block_h_id - (main.player_number - 1)
		#var id_bottom_left_bhi = block_h_id - (main.player_number + 1)
		#
		#if _id in first_lane:
			#occupied_boosts_ids.append(id_right_bhi)
			#occupied_boosts_ids.append(id_bottom_right_bhi)
		#elif _id in last_lane:
			#occupied_boosts_ids.append(id_left_bhi)
			#occupied_boosts_ids.append(id_bottom_left_bhi)
		#else:
			#occupied_boosts_ids.append(id_right_bhi)
			#occupied_boosts_ids.append(id_left_bhi)
			#occupied_boosts_ids.append(id_bottom_right_bhi)
			#occupied_boosts_ids.append(id_bottom_left_bhi)
#
	## Delete the duplicate id from occupied_boosts_ids
	#print("occupied blocks ids before: ", occupied_boosts_ids)
	#occupied_boosts_ids = Array(occupied_boosts_ids.duplicate().reduce(func(acc, item): return acc + [item] if item not in acc else acc, []))
	#print("occupied blocks ids after: ", occupied_boosts_ids)
#
	## Delete the occupied ids from available floor
	#for _occ_id in occupied_boosts_ids:
		#_availabel_floors_arr.erase(_occ_id)

	#return _availabel_floors_arr
