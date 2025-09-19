extends Node3D
class_name AstarMap

var all_points = {}
var a_star = AStar3D.new()
@onready var astar_grid_map = $AstarGridMap

func _ready():
	# Returns an array of all cells with the given item index specified in item.
	var cells = astar_grid_map.get_used_cells()
	#print("cells : ",cells)
	## Get the add point on each astar_grid_map node 
	for cell in cells:
		# Returns the next available point ID with no point associated to it.
		var ind =a_star.get_available_point_id()
		# Adds a new point at the given position with the given identifier.
		# ind as the id start from 0 until 31
		# map_to_local is returns the position of a grid cell in the GridMap's local coordinate space
		a_star.add_point(ind, astar_grid_map.map_to_local(Vector3i(cell.x, cell.y, cell.z)))
		# Append ind (id) to the all_points dictionary
		# Example {(0,0,0) = 0} for id 0, another example for the id 1 {(1,0,0) = 1}
		all_points[v3_to_index(cell)] = ind
	#print("all points: ", all_points)
	
	## Conection between points
	for cell in cells:
		for x in [-1,0,1]:
			for y in [-1,0,1]:
				for z in [-1,0,1]:
					var v3 = Vector3i(x,y,z)
					if v3 == Vector3i(0,0,0):
						continue
					#print("V3 :",v3_to_index(v3 + cell))
					if v3_to_index(v3 + cell) in all_points:
						var ind1 = all_points[v3_to_index(cell)]
						#print("IND 1:",ind1)
						var ind2 = all_points[v3_to_index(cell + v3)]
						#print("IND 2:",ind2)
						# Check if the points are not connected 
						if !a_star.are_points_connected(ind1,ind2):
							# Connect the points
							a_star.connect_points(ind1,ind2,true)
	#print("Connected : ",a_star.get_point_count())

## Return the string Vector 3 (for checking the array)
func v3_to_index(v3):
	return str(int(round(v3.x))) + "," + str(int(round(v3.y))) + "," + str(int(round(v3.z)))

## Get Tiles path 
func get_tiles_path(start, end):
	# Return string 
	var gm_start = v3_to_index(astar_grid_map.local_to_map(start))
	# Return string
	var gm_end = v3_to_index(astar_grid_map.local_to_map(end))
	var start_id = 0
	var end_id = 0
	# Check if the gm_start (string) is in the all_points array
	if gm_start in all_points:
		# Set the start_id (int) to the key of the gm_start from all_points array
		start_id = all_points[gm_start]
	else :
		# Returns the ID of the closest point to to_position
		start_id = a_star.get_closest_point(start)
	# Check if the gm_end (string) is in the all_points array
	if gm_end in all_points:
		# Set the end_id (int) to the key of the end_id from all_points array
		end_id = all_points[gm_end]
	else:
		# Returns the ID of the closest point to to_position
		end_id = a_star.get_closest_point(end)
	# Returns an array with the points that are in the path found by AStar3D between the given points. 
	# The array is ordered from the starting point to the ending point of the path.
	return a_star.get_point_path(start_id, end_id)
