extends Node

var inventory: Dictionary = Dictionary()

signal inventory_changed

func add_collectable(collectabel_name: String) -> void:
	inventory.get_or_add(collectabel_name)
	
	if inventory[collectabel_name] == null:
		inventory[collectabel_name] = 1
	else:
		inventory[collectabel_name] += 1
		
	inventory_changed.emit()
