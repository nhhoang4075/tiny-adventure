extends PanelContainer

const InventorySlotScript = preload("res://scenes/ui/inventory_slot.gd")

@onready var box: HBoxContainer = $MarginContainer/HBoxContainer

var _slots: Array[InventorySlot] = []

func _ready() -> void:
	_build_slots()
	InventoryManager.inventory_changed.connect(_refresh)
	InventoryManager.hotbar_changed.connect(_refresh)
	ToolManager.tool_selected.connect(_on_tool_selected)

func _build_slots() -> void:
	for i in InventoryManager.HOTBAR_SIZE:
		var slot: InventorySlot = InventorySlotScript.new()
		slot.slot_clicked.connect(_on_slot_clicked.bind(i))
		box.add_child(slot)
		_slots.append(slot)
	_refresh()

func _refresh() -> void:
	for i in _slots.size():
		var slot := _slots[i]
		if i < InventoryManager.hotbar.size():
			var id := InventoryManager.hotbar[i]
			slot.set_item(id, InventoryManager.get_count(id))
			slot.set_dim(false)
		else:
			slot.set_item("", 0)
			slot.set_dim(true)
	_update_highlight()

func _on_slot_clicked(_item_id: String, slot_index: int) -> void:
	_activate_slot(slot_index)

func _unhandled_input(event: InputEvent) -> void:
	if BuildingPlacer.is_active() or AnimalPlacer.is_active():
		return
	if event.is_action_pressed("previous"):
		_cycle_tool(-1)
	elif event.is_action_pressed("next"):
		_cycle_tool(1)
	elif event.is_action_pressed("release_tool"):
		ToolManager.select_tool(DataTypes.Tools.None)
	elif event is InputEventKey and event.pressed and not event.echo:
		var idx: int = event.keycode - KEY_1
		if idx >= 0 and idx < _slots.size():
			_activate_slot(idx)

func _activate_slot(idx: int) -> void:
	if idx >= InventoryManager.hotbar.size():
		ToolManager.select_tool(DataTypes.Tools.None)
		return
	var id := InventoryManager.hotbar[idx]
	var data = ItemRegistry.get_item(id)
	if data == null:
		return
	if data.is_tool:
		ToolManager.select_tool(data.tool)
	else:
		ToolManager.select_tool(DataTypes.Tools.None)

func _cycle_tool(direction: int) -> void:
	var hotbar := InventoryManager.hotbar
	if hotbar.is_empty():
		return
	var tool_indices: Array[int] = []
	for i in hotbar.size():
		var d = ItemRegistry.get_item(hotbar[i])
		if d != null and d.is_tool:
			tool_indices.append(i)
	if tool_indices.is_empty():
		return
	var current_pos := -1
	for i in tool_indices.size():
		var d = ItemRegistry.get_item(hotbar[tool_indices[i]])
		if d.tool == ToolManager.selected_tool:
			current_pos = i
			break
	var next_pos: int = (current_pos + direction + tool_indices.size()) % tool_indices.size()
	if current_pos == -1:
		next_pos = 0 if direction > 0 else tool_indices.size() - 1
	_activate_slot(tool_indices[next_pos])

func _on_tool_selected(_tool: DataTypes.Tools) -> void:
	_update_highlight()

func _update_highlight() -> void:
	for i in _slots.size():
		var highlight := false
		if i < InventoryManager.hotbar.size():
			var data = ItemRegistry.get_item(InventoryManager.hotbar[i])
			if data != null and data.is_tool and data.tool == ToolManager.selected_tool and ToolManager.selected_tool != DataTypes.Tools.None:
				highlight = true
		_slots[i].set_highlighted(highlight)
