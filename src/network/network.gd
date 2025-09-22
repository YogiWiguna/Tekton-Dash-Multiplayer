extends Control

@onready var username_line_edit = $NetworkContainer/UsernameInput
@onready var host_button = $NetworkContainer/HostButton
@onready var join_button = $NetworkContainer/JoinButton
@onready var ip_line_edit = $NetworkContainer/IPInput
@onready var network_manager = get_node("/root/NetworkManager")

func _ready():
	host_button.disabled = true
	join_button.disabled = true
	username_line_edit.text_changed.connect(_on_username_text_changed)
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	network_manager.connection_result.connect(_on_connection_result)

func _on_username_text_changed(new_text):
	var is_username_empty = new_text.strip_edges().is_empty()
	host_button.disabled = is_username_empty
	join_button.disabled = is_username_empty

func _on_host_button_pressed():
	"""Handles the host button press event."""
	var player_name = username_line_edit.text
	PlayerData.player_name = player_name
	network_manager.create_server(player_name)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_join_button_pressed():
	"""Handles the join button press event."""
	var player_name = username_line_edit.text
	var ip_address = ip_line_edit.text
	PlayerData.player_name = player_name
	network_manager.join_server(player_name, ip_address)

func _on_connection_result(success: bool):
	"""Handles the result of a connection attempt."""
	if success:
		print("Connection successful! Changing to main scene.")
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		print("Connection failed. Please check the IP address and try again.")
