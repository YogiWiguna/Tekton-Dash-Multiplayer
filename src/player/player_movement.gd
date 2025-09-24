extends Resource
class_name PlayerMovement

var _adjacents_array := []
var occupied_arr := []

# Check the available floor to move
func check_adjacents_floors(_player_current_floor_id: int, _player_number: int, _floors_array, obstacles: Node3D ,level_id):
	# Set the player_current_floor_id into the mouse_selected
	var mouse_selected = _player_current_floor_id
	var map = obstacles.get_parent()
	_adjacents_array = []
	occupied_arr = []
	var check_arr := []
	var temp_adjacents_array := []
	print("player current floor id :", mouse_selected)
	print("player playing : ", map)
	match _player_number:
		3:
			match mouse_selected:
				0:
					var id = [0,0,0,0,1,0,3,4]
					check_arr = id
				1:
					var id = [0,0,0,-1,1,2,3,4]
					check_arr = id
				2:
					var id = [0,0,0,-1,0,2,3,0]
					check_arr = id
				3,6,9,12,15,18,21,24:
					var id = [0,-3,-2,0,1,0,3,4]
					check_arr = id
				4,7,10,13,16,19,22,25:
					var id = [-4,-3,-2,-1,1,2,3,4]
					check_arr = id
				5,8,11,14,17,20,23,26:
					var id = [-4,-3,0,-1,0,2,3,0]
					check_arr = id
				27:
					var id = [0,-3,-2,0,1,0,0,0]
					check_arr = id
				28:
					var id = [-4,-3,-2,-1,1,0,0,0]
					check_arr = id
				29:
					var id = [-4,-3,0,-1,0,0,0,0]
					check_arr = id
		4:
			match mouse_selected:
				# First Row
				0: 
					var id 
					if Global.is_starter:
						id = [0,0,0,0,0,0,4,0] 
					else:
						id = [0,0,0,0,1,0,4,5]
					check_arr = id
				1,2:
					var id 
					if Global.is_starter:
						id = [0,0,0,0,0,0,4,0] 
					else:
						id = [0,0,0,-1,1,3,4,5]
					check_arr = id
				3: 
					var id 
					if Global.is_starter:
						id = [0,0,0,0,0,0,4,0]
					else:
						id = [0,0,0,-1,0,3,4,0]
					check_arr = id
				#0,1,2,3:
					#var id = [0,0,0,0,0,0,4,0]
					#check_arr = id
				# Body Row
				#4:
					#const id = [0,-4,-3,0,1,0,4,5]
					#check_arr = id
				#8,12,16,20,24,28,32:
					#const id = [0,-4,-3,0,1,0,4,5]
					#check_arr = id
				4,8,12,16,20,24,28,32:
					var id = [0,-4,-3,0,1,0,4,5]
					check_arr = id
					if mouse_selected == 32 and map.current_player_node.is_second_lap:
						id = [0,-4,-3,0,1,0,0,0]
						check_arr = id
				#5,6:
					#const id = [0,0,0,-1,1,3,4,5]
					#check_arr = id
				5,6,9,10,13,14,17,18,21,22,25,26,29,30,33,34:
					var id = [-5,-4,-3,-1,1,3,4,5]
					check_arr = id
					var ids = [33,34]
					if mouse_selected in ids and map.current_player_node.is_second_lap:
						id = [-5,-4,-3,-1,1,0,0,0]
						check_arr = id
				#7:
					#const id = [0,0,0,-1,0,3,4,0]
					#check_arr = id
				7,11,15,19,23,27,31,35:
					var id = [-5,-4,0,-1,0,3,4,0]
					check_arr = id
					if mouse_selected == 35 and map.current_player_node.is_second_lap:
						id = [-5,-4,0,-1,0,0,0,0]
						check_arr = id
				#36:
					#var id = [0,-4,-3,0,0,0,0,0]
					#check_arr = id
				#37,38:
					#var id = [-5,-4,-3,0,0,0,0,0]
					#check_arr = id
				#39:
					#var id = [-5,-4,0,0,0,0,0,0]
					#check_arr = id
				# Last Row
				36:
					const id = [0,-4,-3,-2,-1,0,0,0]
					check_arr = id
				37:
					const id = [-5,-4,-3,-2,0,0,0,0]
					check_arr = id
				38:
					const id = [-6,-5,-4,-3,0,0,0,0]
					check_arr = id
				39:
					const id = [-7,-6,-5,-4,0,0,0,0]
					check_arr = id
		5:
			match mouse_selected:
				# First Row
				0:
					var id = [0,0,0,0,1,0,5,6]
					check_arr = id
				1,2,3:
					const id = [0,0,0,-1,1,4,5,0]
					check_arr = id
				4:
					const id = [0,0,0,-1,0,4,5,0]
					check_arr = id
				# Body Row
				# Right Section
				#4,8,12,16,20,24,28,32:
				5,10,15,20,25,30,35,40:
					const id = [0,-5,-4,0,1,0,5,6]
					check_arr = id
				# Mid Section
				#5,6,9,10,13,14,17,18,21,22,25,26,29,30,33,34:
				6,7,8,11,12,13,16,17,18,21,22,23,26,27,28,31,32,33,36,37,38,41,42,43:
					const id = [-6,-5,-4,-1,1,4,5,6]
					check_arr = id
				# Left Section 
				9,14,19,24,29,34,39,44:
					const id = [-6,-5,0,-1,0,4,5,0]
					check_arr = id
				# Last Row
				45:
					const id = [0,-5,-4,0,1,0,0,0]
					check_arr = id
				46,47,48:
					const id = [-6,-5,-4,-1,1,0,0,0]
					check_arr = id
				49:
					const id = [-6,-5,0,-1,0,0,0,0]
					check_arr = id
		6:
			match mouse_selected:
				0:
					const id = [0,0,0,0,1,0,6,7]
					check_arr = id
				1,2,3,4:
					const id = [0,0,0,-1,1,5,6,0]
					check_arr = id
				5:
					const id = [0,0,0,-1,0,5,6,0]
					check_arr = id
				6,12,18,24,30,36,42,48:
					const id = [0,-6,-5,0,1,0,6,7]
					check_arr = id
				7,8,9,10,13,14,15,16,19,20,21,22,25,26,27,28,31,32,33,34,37,38,39,40,43,44,45,46,49,50,51,52:
					const id = [-7,-6,-5,-1,1,5,6,7]
					check_arr = id
				11,17,23,29,35,41,47,53:
					const id = [-7,-6,0,-1,0,5,6,0]
					check_arr = id
				54:
					const id = [0,-6,-5,0,1,0,0,0]
					check_arr = id
				55,56,57,58:
					const id = [-7,-6,-5,-1,1,0,0,0]
					check_arr = id
				59:
					const id = [-7,-6,0,-1,0,0,0,0]
					check_arr = id
	print("check arr : ", check_arr)
	# Append the neighbor array
	if temp_adjacents_array.size() == 0:
		for i in check_arr:
			if i != 0:
				temp_adjacents_array.append(i + mouse_selected)
	print("temp adjacents available : ", temp_adjacents_array)
	# Checking the occupied by player floor 
	for i in range(_floors_array.size()):
		if _floors_array[i].occupied_by_player != null and i in temp_adjacents_array:
			occupied_arr.append(i)
			#print("occupied players : ", occupied_arr)
	
	# Check the _player_current_floor_id in occupied arr
	if _player_current_floor_id in occupied_arr:
		occupied_arr.erase(_player_current_floor_id)
	
	# Check start occupied arr
	if Global.is_starter:
		start_occupied_arr(_player_current_floor_id, _player_number)
	
	# Checking if there's a block horizontal in the adjacents 
	var block_hor_array = obstacle_block_horizontal_occupied_array(_player_current_floor_id, occupied_arr, _player_number, obstacles)
	occupied_arr += block_hor_array
	#print("occupied arr : ", occupied_arr)
	
	# Checking if there's a block vertical in the adjacents 
	var block_ver_array = obstacle_block_vertical_occupied_array(_player_current_floor_id, occupied_arr, _player_number, obstacles)
	occupied_arr += block_ver_array
	
	# Check if the levels arena occupied
	var level_arena_arr = level_arena_occupied(_player_current_floor_id, occupied_arr, _player_number, level_id)
	occupied_arr += level_arena_arr
	#print("level arena arr : ", level_arena_arr)
	# Compare the neighbors array with occupied by player 
	# The result is not matching 
	for i in temp_adjacents_array:
		if i not in occupied_arr:
			_adjacents_array.append(i)
	
	print("Adjacents floor available : ", _adjacents_array)
	#print("Occupied floor : ", occupied_arr)
	
	return _adjacents_array

func obstacle_block_horizontal_occupied_array(player_current_floor_id, _occupied_arr, _player_number, obstacles):
	# Checking if there's a block horizontal in the temp adjacents 
	#print("obstacle block : ", obstacles.blocks_id_array)
	var block_horizontal_array := []
	
	if obstacles.blocks_id_array.size() < 2:
		return []
	
	for i in range(2):
		block_horizontal_array.append(obstacles.blocks_id_array[i])
	#print("block horizontal array : ", block_horizontal_array)
	
	match _player_number:
		5, 6:
			for i in range(1):
				block_horizontal_array.append(obstacles.blocks_special_id_array[i])
	
	for i in block_horizontal_array:
		if player_current_floor_id == i - _player_number:
			_occupied_arr.append(i - 1)
			_occupied_arr.append(i)
			_occupied_arr.append(i + 1)
		elif player_current_floor_id == i - (_player_number - 1) or player_current_floor_id == i - (_player_number + 1):
			_occupied_arr.append(i)
		elif player_current_floor_id == i :
			_occupied_arr.append(i - (_player_number - 1))
			_occupied_arr.append(i - _player_number)
			_occupied_arr.append(i - (_player_number + 1))
		elif player_current_floor_id == i + 1 or player_current_floor_id == i - 1 :
			_occupied_arr.append(i - _player_number)
		else:
			_occupied_arr = []
	
	return _occupied_arr

func obstacle_block_vertical_occupied_array(player_current_floor_id, _occupied_arr, _player_number, obstacles):
	# Checking if there's a block horizontal in the temp adjacents 
	#print("obstacle block : ", obstacles.blocks_id_array)
	var block_vertical_array := []
	
	if obstacles.blocks_id_array.size() < 4:
		return []
	
	for i in range(2,4):
		block_vertical_array.append(obstacles.blocks_id_array[i])
	#print("block vertical array : ", block_vertical_array)
	
	match _player_number:
		6:
			for i in range(1,2):
				block_vertical_array.append(obstacles.blocks_special_id_array[i])
	
	for i in block_vertical_array:
		if player_current_floor_id == i - _player_number or player_current_floor_id == i + _player_number:
			_occupied_arr.append(i - 1)
		elif player_current_floor_id == i - (_player_number + 1) or player_current_floor_id == i + (_player_number - 1):
			_occupied_arr.append(i)
		elif player_current_floor_id == i :
			_occupied_arr.append(i + (_player_number - 1))
			_occupied_arr.append(i - 1)
			_occupied_arr.append(i - (_player_number + 1))
		elif player_current_floor_id == i - 1  :
			_occupied_arr.append(i - _player_number)
			_occupied_arr.append(i)
			_occupied_arr.append(i + _player_number)
		else:
			_occupied_arr = []
	
	return _occupied_arr

func start_occupied_arr(_player_current_floor_id, _player_number):
	var array := []
	if _player_number == 4:
		if _player_current_floor_id == 0:
			array = [1,5]
			occupied_arr += array
		elif _player_current_floor_id == 1:
			array = [0,2,4,6]
			occupied_arr += array
		elif _player_current_floor_id == 2:
			array = [1,3,5,7]
			occupied_arr += array
		elif _player_current_floor_id == 3:
			array = [2,6]
	elif _player_number == 5:
		pass
	elif _player_number == 6:
		pass

func level_arena_occupied(_player_current_floor_id, _occupied_arr, _player_number, _level_id):
	
	# 4 players
	if _player_number == 4:
		# Bridge
		if _level_id == 0:
			var bridge_occupied_arr = [9,20,31]
			_occupied_arr += bridge_occupied_arr
		# Water
		elif _level_id == 4:
			var water_occupied_arr = [11,35]
			_occupied_arr +=  water_occupied_arr
	
	
	# Bridge 6 players
	if _level_id == 0 and _player_number == 6:
		var bridge_occupied_arr = [13,28,29,30,45,54]
		_occupied_arr += bridge_occupied_arr
	
	# Water 5 players
	elif _level_id == 4 and _player_number == 5:
		var water_occupied_arr = [14,15,20,25,44,45]
		_occupied_arr +=  water_occupied_arr
	return _occupied_arr
