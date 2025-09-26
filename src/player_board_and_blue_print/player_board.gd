# Inventory.gd
extends Control

# Get node 
@onready var main = get_node("/root/Main")
@onready var gui = get_parent()
@onready var blue_print = $blue_print
@onready var player_board_bg = $player_board_bg

# Constants for inventory size
const SLOTS = 25
const COLS = 5

# Signal declarations
signal slot_selected(slot_index)
signal slot_deselected
signal slot_targeted(slot_index)  # Renamed from slot_highlighted
signal slot_untargeted  # Renamed from slot_unhighlighted
signal can_move_item(can_move)
signal item_grab_succes
signal item_put_succes
signal item_move_succes

# Array to hold inventory items
var inventory = []
var inventory_slot_array: Array = []
# Cursor load
@onready var cursor_default = load("res://assets/graphics/cursors/cursor_default.png")
@onready var cursor_hold_item = load("res://assets/graphics/cursors/cursor_hold_item.png")
@onready var cursor_release_item = load("res://assets/graphics/cursors/cursor_release_item.png")

# Preload the slot scene
var slot_scene = preload("res://scenes/player_board_and_blue_print/player_board_slot.tscn")

# Preload the shader
const TAKE_TILE_HIGHLIGHT = preload("res://scenes/float_actions_gui/take_tile_highlight.gdshader")

# Reference to the GridContainer node
@onready var grid_container = $player_board_grid
# Tekton
@onready var tekton_player = $tekton_player


# Index of the currently selected slot (-1 if none selected)
var selected_slot = -1
var targeted_slot = -1  # Renamed from highlighted_slot

# Var summon item (grab item)
var is_summon_item = false
var is_hologram_item = false
var item = TextureRect.new()
var id_from_grab_tiles : int
var hologram_array := []

# Var for put item on arena or main
var is_put_item = false
var id_for_put_tiles : int

# Var for move item 
var is_move_item = false
var current_inventory_slot

# Variable for starting tiles
var middle_slots = [6, 7, 8, 11, 12, 13, 16, 17, 18]
var is_item_fill := false

var last_slot_tile_placed : int
var pb_tile_res

func _ready():
	_create_inventory()
	_set_starting_tiles()
	update_pb_bg()


func _process(_delta):
	if is_summon_item:
		item.global_position = get_global_mouse_position()
		Input.set_custom_mouse_cursor(cursor_hold_item)
	
	if is_put_item:
		for _id in range(inventory_slot_array.size()):
			if inventory[_id] != null:
				# Get or create a shader material
				var material = inventory_slot_array[_id].item_sprite.material
				if not material is ShaderMaterial:
					material = ShaderMaterial.new()
					inventory_slot_array[_id].item_sprite.material = material
				# Apply the shader
				material.shader = TAKE_TILE_HIGHLIGHT
	elif !is_put_item :
		for _id in range(inventory_slot_array.size()):
			# Remove the shader but keep the material if it exists
			if inventory_slot_array[_id].item_sprite.material is ShaderMaterial:
				inventory_slot_array[_id].item_sprite.material.shader = null

# Creates the initial inventory grid
func _create_inventory():
	for i in range(SLOTS):
		var slot = slot_scene.instantiate()
		grid_container.add_child(slot,true)
		slot.connect("gui_input", _on_slot_gui_input.bind(i))
		inventory.append(null)
		inventory_slot_array.append(slot)

func _set_starting_tiles():
	await Global.player_number_ready
	var gui = get_parent()
	print("items array : ", gui.players_boards_items_array)
	var _player_boards_items_array =  gui.players_boards_items_array
	#DO the load for first player starting tiles
	inventory = _player_boards_items_array[0]
	set_item_tile_into_slot()


## Set item from blue_print_array into the slot
func set_item_tile_into_slot():
	for _id in range(inventory.size()):
		inventory_slot_array[_id].item = inventory[_id]
	
	is_item_fill = false

# Handles input events on inventory slots
func _on_slot_gui_input(event, slot_index):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(slot_index)

func _on_deselect_slot_button_pressed():
	deselect_slot()

#func _on_spawn_item_button_pressed():
	#spawn_item()

# Checking player who is playing
#func is_any_player_playing() -> bool:
	#return (main.is_player_1_playing or main.is_player_2_playing or
		#main.is_player_3_playing or main.is_player_4_playing or
		#main.is_player_5_playing or main.is_player_6_playing)


# Manages slot selection and item movement
func _handle_click(slot_index):
	print("player board slot index: ", slot_index)

	# Swap tile 
	var current_player_node =  main.current_player_node
	var float_actions_gui =  current_player_node.float_actions_gui
	# Swap tiles Working here
	if inventory[slot_index] != null and float_actions_gui.is_swap_tiles:
		# Own player board tile resource
		pb_tile_res = inventory[slot_index]
		var pb_tile_id = slot_index
		var player_board_selected = gui.character_options.player_board_selected
		
		# Tile Resource bot player board
		var pbs_tile_resource = player_board_selected.tile_resource
		var pbs_tile_id = player_board_selected.tile_id
		
		# Swap tile on own player board
		inventory[pb_tile_id] = pbs_tile_resource
		set_item_tile_into_slot()
		
		# Swap tile on other player board
		player_board_selected.inventory[pbs_tile_id] = pb_tile_res
		player_board_selected.set_item_tile_into_slot()
		
		player_board_selected.is_summon_item = false
		Input.set_custom_mouse_cursor(cursor_default)
		# Remove gui last child
		var last_child = gui.get_child(gui.get_child_count() - 1)
		gui.remove_child(last_child)
		last_child.queue_free() 
		
		deselect_slot()
		
		Global.swap_tile_done.emit()
		return

	# Checking if the click is_swap_tiles is true and inventory slot is null
	elif float_actions_gui.is_swap_tiles and inventory[slot_index] == null:
		deselect_slot()
		return

	# Click slot 
	if selected_slot == -1:
		select_slot(slot_index)
	else:
		if selected_slot == slot_index:
			deselect_slot()
			
			# Set the last slot tile place on pb
			last_slot_tile_placed = slot_index
		else:
			current_inventory_slot = inventory_slot_array[slot_index]
			if main.player_actions == 1:
				check_inventory_slot_is_fill_or_empty(current_inventory_slot)
				return
			# selected_slot is the current selected
			if inventory[selected_slot] == null:
				check_inventory_slot_is_fill_or_empty(current_inventory_slot)
				return
			# Slot index is targeted_slot
			if inventory[slot_index] != null:
				check_inventory_slot_is_fill_or_empty(current_inventory_slot)
				return 
			# Lap 2 restriction
			if Global.is_special_move_on_pb :
				check_inventory_slot_is_fill_or_empty(current_inventory_slot)
				return
			target_slot(slot_index)
			emit_signal("can_move_item", true)
			move_item_to_targeted()
			# Checking for player turn
			# Set the player action into zero after move tiles on player board for end the turn
			main.player_actions = 0

# Selects a slot and emits a signal
# Update the select_slot function
func select_slot(slot_index):
	selected_slot = slot_index
	#print("slot index : ", slot_index)
	last_slot_tile_placed = slot_index
	_update_slot_visual(slot_index)
	emit_signal("slot_selected", slot_index)
	_highlight_adjacent_slots()
	# Check selected inventory slot after action button is pressed
	# Grab button is pressed
	current_inventory_slot = inventory_slot_array[slot_index]
	if is_summon_item:
		# Check if the current slot is item fil true 
		if current_inventory_slot.is_item_fill:
			check_inventory_slot_is_fill_or_empty(current_inventory_slot)
			return
		# Set the custom mouse when relase the item 
		Input.set_custom_mouse_cursor(cursor_release_item)
		spawn_item_on_board(slot_index)
	# Put button is pressed
	elif is_put_item:
		put_item_from_board(slot_index)
		

func check_inventory_slot_is_fill_or_empty(_current_inventory_slot) :
	# Show the error indicator that show we can't put on the current selection board
	_current_inventory_slot.error_indicator.show()
	# Deselect the tiles
	deselect_slot()
	await get_tree().create_timer(0.3).timeout
	# Hide the error after 0.3 second of timer
	_current_inventory_slot.error_indicator.hide()

# Add this new function to get adjacent slot indices
# Updated function to get adjacent slot indices
func get_adjacent_slots(slot_index):
	var adjacent = []
	var row = slot_index / COLS
	var col = slot_index % COLS
	
	if row > 0:
		adjacent.append(slot_index - COLS)  # Up
	if row < COLS - 1:
		adjacent.append(slot_index + COLS)  # Down
	if col > 0:
		adjacent.append(slot_index - 1)  # Left
	if col < COLS - 1:
		adjacent.append(slot_index + 1)  # Right
	
	return adjacent

# Moore Neighborhood Checker with row and col 
func get_adjacent_slots_all_directions(slot_index):
	var adjacent = []
	var row = slot_index / COLS
	var col = slot_index % COLS
	# Up
	if row > 0:
		adjacent.append(slot_index - COLS)  # Up
		if col > 0:
			adjacent.append(slot_index - COLS - 1)  # Up-Left
		if col < COLS - 1:
			adjacent.append(slot_index - COLS + 1)  # Up-Right
	# Down
	if row < COLS - 1:
		adjacent.append(slot_index + COLS)  # Down
		if col > 0:
			adjacent.append(slot_index + COLS - 1)  # Down-Left
		if col < COLS - 1:
			adjacent.append(slot_index + COLS + 1)  # Down-Right
	# Left and Right
	if col > 0:
		adjacent.append(slot_index - 1)  # Left
	if col < COLS - 1:
		adjacent.append(slot_index + 1)  # Right
	
	return adjacent


# Update the target_slot function to use can_move_to_target
func target_slot(slot_index):
	#print("Target Slot")
	if targeted_slot != -1:
		untarget_slot()
	print("Special move pb")

	targeted_slot = slot_index
	Global.is_special_move_on_pb = true
	_update_slot_visual(slot_index)
	emit_signal("slot_targeted", slot_index)
	emit_signal("can_move_item", can_move_to_target())
	if is_move_item:
		pass
		
func untarget_slot():
	if targeted_slot != -1:
		var old_targeted = targeted_slot
		targeted_slot = -1
		_update_slot_visual(old_targeted)
		emit_signal("slot_untargeted")
		emit_signal("can_move_item", false)

# Deselects the currently selected slot and emits a signal
# Update the deselect_slot function
func deselect_slot():
	var old_selected = selected_slot
	selected_slot = -1
	if old_selected != -1:
		_update_slot_visual(old_selected)
	emit_signal("slot_deselected")
	untarget_slot()
	emit_signal("can_move_item", false)
	_highlight_adjacent_slots()  # This will clear all highlights

# Spawns a random item in the selected slot if it's empty
func summon_item(id):
	var _item_summon = TextureRect.new()
	# Set the item to new TextureRect
	item = _item_summon
	# Set the is_summon_item into true after the grab button is active
	# is_summon_item will call function spawn_item_on_board from function selected_slot
	is_summon_item = true
	# Set the id from the current tiles (id from obstacle.gd)
	id_from_grab_tiles = id
	# Set the item texture from item_list 
	# The id for item list is the same with item_list on obstacle.gd
	item.texture = Global.item_material_list[id].texture
	# Set the item texture on mouse position into the hologram tiles
	if is_hologram_item:
		item.texture = Global.tiles_hologram_material_list[id].texture
		hologram_array.append(Global.tiles_hologram_material_list[id])
	# Set the mouse filter
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Add item as the child to current parent (Inventory)
	self.add_child(item)


func spawn_item_on_board(_slot_index):
	# Set the is_summon_item into false after player put the tiles on player board
	is_summon_item = false
	# Get the current item from item_list
	var _item = Global.item_material_list[id_from_grab_tiles]
	# Set the item for spawn if the hologram tiles is grabed
	if is_hologram_item:
		_item = Global.tiles_hologram_material_list[id_from_grab_tiles]
		#is_hologram_item = false
	# Load the item to player board
	load_item(_item, _slot_index)
	# Delete the item from tree
	item.queue_free()
	# Deseelct the slot 
	deselect_slot()
	item_grab_succes.emit()
	# Set timeout for custom mouse 
	await get_tree().create_timer(.5).timeout
	# Set the mouse into default mode 
	Input.set_custom_mouse_cursor(cursor_default)

# PUT ITEM
# Select the item from player board and then will show it to the cuurent player place
func put_item_from_board(_slot_index):
	# Ensure the selected slot has an item.
	var selected_mat = inventory[_slot_index]
	if selected_mat == null:
		check_inventory_slot_is_fill_or_empty(inventory_slot_array[_slot_index])
		return

	# --- NEW LOGIC: Find the ID of the selected material ---
	var item_id = -1
	var is_hologram = false

	# Check if it's a normal material
	item_id = Global.item_material_list.find(selected_mat)
	
	# If not found, check if it's a hologram material
	if item_id == -1:
		item_id = Global.tiles_hologram_material_list.find(selected_mat)
		if item_id != -1:
			is_hologram = true

	# If the material is not found in either list, something is wrong.
	if item_id == -1:
		print("ERROR: Could not identify the selected tile material.")
		return

	# --- Send the ID and hologram status to the server ---
	var floor_id = main.current_player_node.current_player_floor_id
	if multiplayer.is_server():
		main.request_put_tile(floor_id, item_id, is_hologram)
	else:
		main.request_put_tile.rpc_id(1, floor_id, item_id, is_hologram)

	# --- Update local UI ---
	id_for_put_tiles = _slot_index
	deselect_slot()
	item_put_succes.emit()
	delete_item(_slot_index) # Remove item from the local player's board
	is_put_item = false

# Moves or swaps items between the selected slot and target slot
func move_item_to_targeted():
	if can_move_to_target():
		if inventory[selected_slot] != null:
			if inventory[targeted_slot] == null:
				move_item(selected_slot, targeted_slot)
			else:
				swap_items(selected_slot, targeted_slot)
		deselect_slot()
		#select_slot(targeted_slot)
	untarget_slot()

# Bool can_move_to target
# Updated can_move_to_target function using get_adjacent_slots
func can_move_to_target() -> bool:
	if selected_slot == -1 or targeted_slot == -1 or selected_slot == targeted_slot:
		return false
	
	return get_adjacent_slots(selected_slot).has(targeted_slot)

# Deletes the item in the selected slot
func delete_selected_item():
	if selected_slot != -1 and inventory[selected_slot] != null:
		delete_item(selected_slot)

# Add this new function to highlight adjacent slots
func _highlight_adjacent_slots():
	for i in range(SLOTS):
		var slot = grid_container.get_child(i)
		slot.set_adjacent_highlight(false)
	
	if selected_slot != -1:
		var adjacent_slots = get_adjacent_slots(selected_slot)
		for adj_slot in adjacent_slots:
			var slot = grid_container.get_child(adj_slot)
			slot.set_adjacent_highlight(true)

# Updates the visual representation of a slot
func _update_slot_visual(slot_index):
	var slot = grid_container.get_child(slot_index)
	if slot:
		slot.set_item(inventory[slot_index])
		slot.set_selected(slot_index == selected_slot) # Return bool
		slot.set_targeted(slot_index == targeted_slot) # Return bool
		if selected_slot != -1:
			slot.set_adjacent_highlight(get_adjacent_slots(selected_slot).has(slot_index))
		else:
			slot.set_adjacent_highlight(false)

# Loads an item into a specific slot
func load_item(_item, slot_index):
	if slot_index < 0 or slot_index >= SLOTS:
		return false
	if inventory[slot_index] != null:
		return false
	inventory[slot_index] = _item
	_update_slot_visual(slot_index)
	return true

# Removes an item from a specific slot
func delete_item(slot_index):
	if slot_index < 0 or slot_index >= SLOTS:
		return false
	if inventory[slot_index] == null:
		return false
	inventory[slot_index] = null
	_update_slot_visual(slot_index)
	return true

# Moves an item from one slot to another
func move_item(from_index, to_index):
	if from_index < 0 or from_index >= SLOTS or to_index < 0 or to_index >= SLOTS:
		return false
	if inventory[from_index] == null or inventory[to_index] != null:
		return false
	inventory[to_index] = inventory[from_index]
	inventory[from_index] = null
	_update_slot_visual(from_index)
	_update_slot_visual(to_index)
	return true

# Swaps items between two slots
func swap_items(index1, index2):
	if index1 < 0 or index1 >= SLOTS or index2 < 0 or index2 >= SLOTS:
		return false
	var temp = inventory[index1]
	inventory[index1] = inventory[index2]
	inventory[index2] = temp
	_update_slot_visual(index1)
	_update_slot_visual(index2)
	return true


# -------------------------------------------------------------------------
# Player Board Background
# -------------------------------------------------------------------------
const pb_bg_copper = preload("res://assets/graphics/player_board_and_blue_print/pb_bg/player_board_bigbg_1.png")
const pb_bg_dabro = preload("res://assets/graphics/player_board_and_blue_print/pb_bg/player_board_bigbg_2.png")
const pb_bg_gatot = preload("res://assets/graphics/player_board_and_blue_print/pb_bg/player_board_bigbg_3.png")
const pb_bg_pip = preload("res://assets/graphics/player_board_and_blue_print/pb_bg/player_board_bigbg_4.png")

var pb_bgs = [pb_bg_pip, pb_bg_copper,pb_bg_dabro, pb_bg_gatot]

func update_pb_bg():
	var player_id_arr = Global.get_player_ids().values()
	player_board_bg.texture = pb_bgs[player_id_arr[0]]
