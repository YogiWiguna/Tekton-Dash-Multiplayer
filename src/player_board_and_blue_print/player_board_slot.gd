# InventorySlot.gd
extends Panel

@onready var item_sprite = $item_sprite
@onready var selection_indicator = $selection_indicator
@onready var adjacent_indicator = $adjacent_indicator
@onready var target_indicator = $target_indicator
@onready var error_indicator = $error_indicator


var item = null
var selected = false
var targeted = false
var adjacent_highlight = false
var is_item_fill = false


func _process(_delta):
	if item == null:
		is_item_fill = false
		set_item(item)
	else :
		is_item_fill = true
		set_item(item)

func set_item(new_item):
	item = new_item
	if item:
		item_sprite.texture = item.texture
		item_sprite.show()
	else:
		item_sprite.hide()

func set_selected(value):
	selected = value
	selection_indicator.visible = value
	#select_button.visible = value

func set_targeted(value):
	targeted = value
	if adjacent_indicator.visible:
		adjacent_indicator.set_visible(false)
	target_indicator.visible = value
	#target_button.visible = value

func set_adjacent_highlight(value):
	adjacent_highlight = value
	adjacent_indicator.visible = value
	#adjacent_button.visible = value

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		#get_parent().get_parent().get_parent().emit_signal("gui_input", event)

func _on_mouse_entered():
	selection_indicator.show()

func _on_mouse_exited():
	selection_indicator.hide()
