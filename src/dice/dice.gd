extends Node3D

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ---   DiceManager.gd         ---
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

signal roll_completed(result: int, player_id: int, face_name: String)

@onready var dice_mesh: MeshInstance3D = $DiceMesh
@onready var face_label: Label3D = $FaceLabel

var is_rolling: bool = false
var final_result: int = 1
var initial_position: Vector3
var initial_rotation: Vector3

const FACE_NAMES = {
	1: "Regular in spawn", # Regular
	2: "Regular under you", # Regular come to you
	3: "Special in spawn", # Special
	4: "Special in spawn", # Special 
	5: "Zonkk", # Dont get it
	6: "Regular in spawn" # Regular
}

const FACE_ROTATIONS = {
	1: Vector3(0, 0, 0),
	2: Vector3(0, 0, -PI/2),
	3: Vector3(-PI/2, 0, 0),
	4: Vector3(PI/2, 0, 0),
	5: Vector3(0, 0, PI/2),
	6: Vector3(PI, 0, 0)
}


func _ready():
	initial_position = dice_mesh.position
	initial_rotation = dice_mesh.rotation
	# Ensure the origin is at the center of the mesh
	dice_mesh.transform.origin = Vector3.ZERO
	update_face_label(1)

func update_face_label(face_number: int):
	if face_label:
		face_label.text = FACE_NAMES[face_number]

# This function is now ONLY for the SERVER to generate a random number.
func roll() -> void:
	if is_rolling:
		return
		
	is_rolling = true
	final_result = randi_range(1, 6)
	print("SERVER DICE ROLLED: ", final_result)
	_play_roll_animation()

# This new function is for CLIENTS. It shows the result WITHOUT generating a new number.
func show_roll_animation(result_from_server: int):
	if is_rolling:
		return
	
	is_rolling = true
	# It uses the result given by the server.
	final_result = result_from_server
	show() # Make sure the dice is visible for everyone
	print("CLIENT playing animation for result: ", final_result)
	_play_roll_animation()
	
# This is the shared animation logic used by both server and clients.
func _play_roll_animation() -> void:
	var tween = create_tween()
	
	if face_label:
		face_label.visible = false
	
	# Animation parameters
	var jump_height = 0.5
	var spin_duration = 1.0
	
	tween.set_parallel(true)
	
	# Small jump up and down
	tween.tween_property(dice_mesh, "position:y", 
		initial_position.y + jump_height, 
		spin_duration * 0.5
	).set_trans(Tween.TRANS_SINE)
	
	tween.chain().tween_property(dice_mesh, "position:y",
		initial_position.y,
		spin_duration * 0.5
	).set_trans(Tween.TRANS_SINE)
	
	# Spinning around center
	tween.tween_property(dice_mesh, "rotation",
		Vector3(
			dice_mesh.rotation.x + PI * 2,
			dice_mesh.rotation.y + PI * 4,
			dice_mesh.rotation.z + PI * 2
		),
		spin_duration
	).set_trans(Tween.TRANS_SINE)
	
	# Final rotation to show result
	tween.chain().tween_property(dice_mesh, "rotation",
		FACE_ROTATIONS[final_result],
		0.2
	).set_trans(Tween.TRANS_SINE)
	
	tween.finished.connect(_on_roll_animation_completed)

func _on_roll_animation_completed() -> void:
	is_rolling = false
	if face_label:
		face_label.visible = true
		var label_tween = create_tween()
		face_label.scale = Vector3.ZERO
		label_tween.tween_property(face_label, "scale",
			Vector3.ONE,
			0.3
		).set_trans(Tween.TRANS_ELASTIC)
	update_face_label(final_result)
	roll_completed.emit(final_result, 1, FACE_NAMES[final_result])
	Global.dice_rolled.emit()
	await get_tree().create_timer(1.0).timeout
	self.hide()
