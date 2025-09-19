extends GridMap
class_name AstarGridMap
@onready var main = get_node("/root/Main")

func _ready():
	set_astar_grid_map()

func set_astar_grid_map():
	
	#print("player number astar : ", map.player_number)
	for x in range(main.default_rows):
		for z in range(main.player_number):
			var pos_x = x 
			#print("x",x)
			var pos_z = z 
			#print("z",z)
			self.set_cell_item(Vector3(pos_x, 0, pos_z),0)
