class_name InventorySlot
extends PanelContainer

signal slot_clicked(item_id: String)

const SLOT_SIZE := Vector2(32, 32)

var item_id: String = ""
var _icon: TextureRect
var _count_label: Label

func _ready() -> void:
	custom_minimum_size = SLOT_SIZE
	theme_type_variation = &"InventoryItemPanel"
	mouse_filter = MOUSE_FILTER_STOP

	_icon = TextureRect.new()
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.size_flags_vertical = Control.SIZE_FILL
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)

	_count_label = Label.new()
	_count_label.theme_type_variation = &"InventoryLabel"
	_count_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	_count_label.size_flags_vertical = Control.SIZE_SHRINK_END
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count_label)

func set_item(id: String, count: int) -> void:
	item_id = id
	if id == "":
		_icon.texture = null
		_count_label.text = ""
		return
	var data = ItemRegistry.get_item(id)
	if data == null:
		_icon.texture = null
		_count_label.text = ""
		return
	_icon.texture = data.icon
	_count_label.text = str(count) if count > 1 else ""

func set_dim(dim: bool) -> void:
	modulate.a = 0.35 if dim else 1.0

func set_highlighted(on: bool) -> void:
	self_modulate = Color(1.4, 1.4, 0.6) if on else Color.WHITE

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if item_id != "":
			slot_clicked.emit(item_id)
			accept_event()
