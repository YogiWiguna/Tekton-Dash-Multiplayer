# InventorySlot.gd
extends Panel

@onready var item_sprite = $item_sprite

var item = null
var is_item_fill = false


func _process(_delta):
	if item == null:
		is_item_fill = false
		set_item(item)
	else :
		is_item_fill = true
		set_item(item)

#func _unhandled_input(_event):
	#if item == null:
		#is_item_fill = false
		#set_item(item)
	#else :
		#is_item_fill = true
		#set_item(item)

func set_item(new_item):
	item = new_item
	if item:
		item_sprite.texture = item.texture
		item_sprite.show()
	else:
		item_sprite.hide()
