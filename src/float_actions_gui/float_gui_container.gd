@tool
extends Container
class_name CircularContainer

@export var radius: float = 150.0
@export var arc_angle: float = 130.0
@export var start_angle: float = 205.0
@export var clockwise: bool = true
@export var align_center: bool = true

var manual_positions = {}

func _ready():
	arrange_children()

func _get_minimum_size() -> Vector2:
	return Vector2(radius * 2, radius * 3)

func arrange_children():
	var children = get_children()
	var child_count = children.size()
	
	if child_count == 0:
		return
	
	var angle_step = arc_angle / (child_count - 1) if child_count > 1 else 0.0
	
	for i in range(child_count):
		var child = children[i]
		var angle = deg_to_rad(start_angle + (i * angle_step if clockwise else (arc_angle - i * angle_step)))
		
		var x = radius * cos(angle)
		var y = radius * sin(angle)
		
		# Check if this child has a manual position
		var child_name = child.name
		if manual_positions.has(child_name):
			# Center the child at the manual position
			child.position = manual_positions[child_name] - (child.size / 2)
		else:
			if align_center:
				child.position = Vector2(x, y) + Vector2(radius, radius) - (child.size/2)
			else:
				child.position = Vector2(x, y) + Vector2(radius, radius)	
