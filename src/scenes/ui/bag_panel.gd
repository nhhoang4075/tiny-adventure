extends CanvasLayer

const InventorySlotScript = preload("res://scenes/ui/inventory_slot.gd")
const GRID_COLUMNS := 10
const GRID_ROWS := 5

@onready var grid: GridContainer = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Grid
@onready var backdrop: ColorRect = $Backdrop

var _slots_by_id: Dictionary = {}

func _ready() -> void:
	visible = false
	grid.columns = GRID_COLUMNS
	_build_slots()
	InventoryManager.inventory_changed.connect(_refresh)
	InventoryManager.hotbar_changed.connect(_refresh)

func _build_slots() -> void:
	var total := GRID_COLUMNS * GRID_ROWS
	for i in total:
		var slot: InventorySlot = InventorySlotScript.new()
		grid.add_child(slot)
		if i < ItemRegistry.ordered_ids.size():
			var id := ItemRegistry.ordered_ids[i]
			slot.slot_clicked.connect(_on_slot_clicked)
			_slots_by_id[id] = slot
	_refresh()

func _refresh() -> void:
	for id in ItemRegistry.ordered_ids:
		if not _slots_by_id.has(id):
			continue
		var slot: InventorySlot = _slots_by_id[id]
		if InventoryManager.has_item(id):
			slot.set_item(id, InventoryManager.get_count(id))
			slot.set_highlighted(InventoryManager.is_pinned(id))
		else:
			slot.set_item("", 0)
			slot.set_highlighted(false)

func _on_slot_clicked(item_id: String) -> void:
	if not InventoryManager.has_item(item_id):
		return
	InventoryManager.toggle_pin(item_id)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_bag"):
		visible = not visible
		get_viewport().set_input_as_handled()
