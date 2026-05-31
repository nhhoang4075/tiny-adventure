extends CanvasLayer

const InventorySlotScript = preload("res://scenes/ui/inventory_slot.gd")
const GRID_COLUMNS := 10
const GRID_ROWS := 5

@onready var grid: GridContainer = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Grid
@onready var backdrop: ColorRect = $Backdrop

var _slots: Array[InventorySlot] = []

func _ready() -> void:
	visible = false
	grid.columns = GRID_COLUMNS
	_build_slots()
	InventoryManager.inventory_changed.connect(_refresh)
	InventoryManager.hotbar_changed.connect(_refresh)

func _build_slots() -> void:
	# Tạo sẵn lưới ô; mỗi ô có thể hiển thị BẤT KỲ vật phẩm nào (không fix theo id).
	var total := GRID_COLUMNS * GRID_ROWS
	for i in total:
		var slot: InventorySlot = InventorySlotScript.new()
		slot.slot_clicked.connect(_on_slot_clicked)
		grid.add_child(slot)
		_slots.append(slot)
	_refresh()

func _refresh() -> void:
	# Dồn các vật phẩm đang sở hữu vào đầu lưới (theo thứ tự ItemRegistry.ordered_ids
	# = sort_order). Hết số lượng → has_item false → tự biến mất, các ô sau dồn lên.
	var owned: Array[String] = []
	for id in ItemRegistry.ordered_ids:
		if InventoryManager.has_item(id):
			owned.append(id)

	for i in _slots.size():
		var slot := _slots[i]
		if i < owned.size():
			var id := owned[i]
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
