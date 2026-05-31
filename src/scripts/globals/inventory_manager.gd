extends Node

const HOTBAR_SIZE: int = 6
const DEFAULT_HOTBAR: Array[String] = ["axe", "pickaxe", "hoe", "watering_can", "seed_wheat", "seed_tomato"]

var inventory: Dictionary = Dictionary()
var hotbar: Array[String] = []

signal inventory_changed
signal hotbar_changed

func _ready() -> void:
	if hotbar.is_empty():
		hotbar = DEFAULT_HOTBAR.duplicate()
		hotbar_changed.emit()

func add_collectable(collectable_name: String) -> void:
	inventory.get_or_add(collectable_name)

	if inventory[collectable_name] == null:
		inventory[collectable_name] = 1
	else:
		inventory[collectable_name] += 1

	inventory_changed.emit()

func has_item(item_id: String) -> bool:
	var data = ItemRegistry.get_item(item_id)
	if data == null:
		return false
	if data.is_tool:
		return true
	return get_count(item_id) > 0

func get_count(item_id: String) -> int:
	var data = ItemRegistry.get_item(item_id)
	if data == null:
		return 0
	if data.is_tool:
		return 1
	var v = inventory.get(item_id)
	if v == null:
		return 0
	return v

func pin_to_hotbar(item_id: String) -> bool:
	if hotbar.has(item_id):
		return false
	if hotbar.size() >= HOTBAR_SIZE:
		return false
	hotbar.append(item_id)
	hotbar_changed.emit()
	return true

func unpin_from_hotbar(item_id: String) -> void:
	if hotbar.has(item_id):
		hotbar.erase(item_id)
		hotbar_changed.emit()

func toggle_pin(item_id: String) -> bool:
	if hotbar.has(item_id):
		unpin_from_hotbar(item_id)
		return false
	return pin_to_hotbar(item_id)

func is_pinned(item_id: String) -> bool:
	return hotbar.has(item_id)

## Bớt 1 item (dùng cho cho ăn / bán). Khi về 0: xoá khỏi túi và gỡ khỏi hotbar.
func remove_collectable(collectable_name: String) -> void:
	var current = inventory.get(collectable_name)
	if current == null or current <= 0:
		return
	current -= 1
	if current <= 0:
		inventory.erase(collectable_name)
		# Hết số lượng → tự gỡ khỏi hotbar (ngăn 6 ô) luôn.
		if hotbar.has(collectable_name):
			hotbar.erase(collectable_name)
			hotbar_changed.emit()
	else:
		inventory[collectable_name] = current
	inventory_changed.emit()
