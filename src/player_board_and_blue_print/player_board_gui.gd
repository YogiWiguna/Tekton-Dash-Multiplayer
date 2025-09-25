extends Control

var slot_scene = preload("res://scenes/player_board_and_blue_print/blue_print_slot.tscn")

@onready var cursor_default = load("res://assets/graphics/cursors/cursor_default.png")
@onready var player_board = get_node("/root/map/gui/player_board")
@onready var gui = get_node("/root/map/gui")
@onready var map = get_node("/root/map")
@onready var player_board_grid = $player_board_grid

const slots : int = 25

var is_item_fill := false

var player_board_gui_inventory :=  []
var player_board_gui_slots_array := []


# Variable for starting tiles
var middle_slots = [6, 7, 8, 11, 12, 13, 16, 17, 18]

var id_for_put_tiles 
var is_hologram_item := false

func _ready():
	_create_inventory()
	
	await Global.player_number_ready
	_set_starting_tiles(2)

func _process(_delta):
	if is_item_fill:
		set_item_tile_into_slot()

func _create_inventory():
	for i in range(slots):
		var _slot = slot_scene.instantiate()
		player_board_grid.add_child(_slot,true)
		player_board_gui_inventory.append(null)
		player_board_gui_slots_array.append(_slot)

func _set_starting_tiles(number_of_resources: int = 1):
	# Get available middle slots
	var available_middle_slots = []
	for slot in middle_slots:
		if player_board_gui_inventory[slot] == null:
			available_middle_slots.append(slot)
	
	# Spawn resources in random available middle slots
	for player in range(0, map.player_number):
		for i in range(min(number_of_resources, available_middle_slots.size())):
			# Get random slot
			var random_index = randi() % available_middle_slots.size()
			var chosen_slot = available_middle_slots[random_index]
			
			# Get random resource from Global.item_material_list
			var random_resource = randi() % Global.item_material_list.size()
			var chosen_resource = Global.item_material_list[random_resource]
			
			# Spawn the randomly chosen resource
			gui.players_boards_items_array[player][chosen_slot] = chosen_resource
			
			# Remove the used slot from available slots
			available_middle_slots.remove_at(random_index)

# Set item from blue_print_array into the slot
func set_item_tile_into_slot():
	for _id in range(player_board_gui_inventory.size()):
		player_board_gui_slots_array[_id].item = player_board_gui_inventory[_id]
	
	is_item_fill = false

func spawn_item_on_board(item_id, id_from_grab_tiles, player_board_array):
	# Get the current item from item_list
	var _item = Global.item_material_list[item_id]
	# Set the item for spawn if the hologram tiles is grabed
	if is_hologram_item:
		_item = Global.tiles_hologram_material_list[item_id]
		#is_hologram_item = false
	match id_from_grab_tiles:
		0: id_from_grab_tiles = 6
		1: id_from_grab_tiles = 7
		2: id_from_grab_tiles = 8
		3: id_from_grab_tiles = 11
		4: id_from_grab_tiles = 12
		5: id_from_grab_tiles = 13
		6: id_from_grab_tiles = 16
		7: id_from_grab_tiles = 17
		8: id_from_grab_tiles = 18
	
	player_board_array[id_from_grab_tiles] = _item
	
	# Set timeout for custom mouse 
	await get_tree().create_timer(.5).timeout
	# Set the mouse into default mode 
	Input.set_custom_mouse_cursor(cursor_default)
	
	return player_board_array

## BOT Player Board 
func update_player_board_gui(player):
	player_board_gui_inventory = gui.players_boards_items_array[player]
	is_item_fill = true
