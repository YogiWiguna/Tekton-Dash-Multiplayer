class_name TileManager
extends Node3D

@onready var main = get_node("/root/Main/")
@onready var floors_and_tiles_regions = get_node("/root/Main/FloorsAndTileManager")
@onready var obstacles = get_node("/root/Main/Obstacles")
@onready var token_tile = $token_tile
@onready var token_tile_2 = $token_tile2
@onready var token_tile_3 = $token_tile3
@onready var obstacle_tile = $obstacle_tile
@onready var obstacle_tile_animation = $obstacle_tile_animation
@onready var hover_movement_tile = $hover_movement_tile
@onready var tile_hologram = $tile_hologram
@onready var block_horizontal = $block_horizontal
@onready var block_vertical = $block_vertical
@onready var hover_tile = $hover_tile
#@onready var explosion = $explosion
#@onready var swap_position = $swap_position
#@onready var freeze = $freeze
#@onready var book_tiles = $book_tiles
@onready var animation_player = $animation_player


var tiles_holograms = ["tile_coin_hologram", "tile_diamond_hologram", "tile_heart_hologram", "tile_star_hologram"]
var stacks = ["stack", "stack_special"]
var materials_initialized = false  # New flag to track initialization
var is_being_hovered = false      # New flag to track hover state

func _ready():
	# Connect visibility changed signals
	token_tile_2.visibility_changed.connect(_on_token_tile_visibility_changed)
	token_tile_3.visibility_changed.connect(_on_token_tile_visibility_changed)
	# Initial material setup
	initialize_materials()

func _process(_delta):
	
	#Only update materials if not being hovered and not yet initialized
	if not is_being_hovered and not materials_initialized:
		change_material_for_stack()
		materials_initialized = true

func _on_token_tile_visibility_changed():
	# Reset initialization flag and update materials when visibility changes
	materials_initialized = false
	change_material_for_stack()
	materials_initialized = true

func initialize_materials():
	change_material_for_stack()
	materials_initialized = true

func set_hover_state(hovering: bool):
	is_being_hovered = hovering
	if not hovering:
		materials_initialized = false

func get_unique_material(base_material: Material) -> Material:
	return base_material.duplicate(true)

func should_update_material(tile: Node3D) -> bool:
	return tile.visible and (not tile.get_surface_override_material(0) or not materials_initialized)

func set_tile_material(tile: Node3D, material_name: String, is_hologram: bool = false, is_transparent: bool = false):
	# Only proceed if the tile is visible
	if not tile.visible:
		return
		
	var material_map = {
		"tile_heart": {
			"normal": Global.heart_tile_surface_mat,
			"transparent": Global.heart_tile_trans_surface_mat,
			"hologram": Global.heart_hologram_tile_surface_mat,
			"hologram_trans": Global.heart_tile_hologram_trans_surface_mat
		},
		"tile_star": {
			"normal": Global.star_tile_surface_mat,
			"transparent": Global.star_tile_trans_surface_mat,
			"hologram": Global.star_hologram_tile_surface_mat,
			"hologram_trans": Global.star_tile_hologram_trans_surface_mat
		},
		"tile_diamond": {
			"normal": Global.diamond_tile_surface_mat,
			"transparent": Global.diamond_tile_trans_surface_mat,
			"hologram": Global.diamond_hologram_tile_surface_mat,
			"hologram_trans": Global.diamond_tile_hologram_trans_surface_mat
		},
		"tile_coin": {
			"normal": Global.coin_tile_surface_mat,
			"transparent": Global.coin_tile_trans_surface_mat,
			"hologram": Global.coin_hologram_tile_surface_mat,
			"hologram_trans": Global.coin_tile_hologram_trans_surface_mat
		}
	}

	var base_name = material_name.replace("_hologram", "")
	if base_name in material_map:
		var material_type = "normal"
		if is_hologram and is_transparent:
			material_type = "hologram_trans"
		elif is_hologram:
			material_type = "hologram"
		elif is_transparent:
			material_type = "transparent"
			
		var base_material = material_map[base_name][material_type]
		tile.set_surface_override_material(0, get_unique_material(base_material))

func change_material_for_stack():
	var obstacle_surface = obstacle_tile.get_surface_override_material(0)
	if not obstacle_surface or not (obstacle_surface.resource_name in stacks):
		return

	# Process token_tile
	var token_surface = token_tile.get_surface_override_material(0)
	if token_surface and token_tile.visible:
		var is_hologram = "hologram" in token_surface.resource_name
		set_tile_material(token_tile, token_surface.resource_name, is_hologram, false)

	# Process token_tile_2
	if token_tile_2.visible:
		var token_2_surface = token_tile_2.get_surface_override_material(0)
		if token_2_surface and obstacle_surface.resource_name in stacks:
			# Update token_tile with transparent material
			if token_surface:
				var is_hologram = "hologram" in token_surface.resource_name
				set_tile_material(token_tile, token_surface.resource_name, is_hologram, true)
			
			# Update token_tile_2 with transparent material
			var is_hologram_2 = "hologram" in token_2_surface.resource_name
			set_tile_material(token_tile_2, token_2_surface.resource_name, is_hologram_2, true)

	# Process token_tile_3
	if token_tile_3.visible:
		var token_3_surface = token_tile_3.get_surface_override_material(0)
		if token_3_surface and obstacle_surface.resource_name == "stack_special":
			var is_hologram_3 = "hologram" in token_3_surface.resource_name
			set_tile_material(token_tile_3, token_3_surface.resource_name, is_hologram_3, true)
