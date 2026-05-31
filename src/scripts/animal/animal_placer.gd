extends Node

## Vật nuôi là ITEM trong túi.
##
## ĐẶT (kiểu Minecraft): chọn item con vật trên hotbar → đi VÀO trong chuồng (qua
##   cổng) → nhấn F → đặt 1 con (tốn 1 item). Không cần chế độ chuột.
##
## MUA (tạm thời tới khi có shop) — chế độ H:
##   H            : bật/tắt xem trước để mua
##   Tab          : đổi loài
##   Enter / click: mua 1 con loài hiện tại (tốn vàng → +1 item vào túi)
##   Esc / phải   : thoát

const ANIMALS_DIR := "res://resources/animals/"
const VALID_TINT := Color(1, 1, 1, 0.85)
const INVALID_TINT := Color(1.0, 0.4, 0.4, 0.85)

var _defs: Array[AnimalDef] = []
var _index: int = 0
var _active: bool = false
var _ghost: Node2D

func _ready() -> void:
	_load_defs()

func _load_defs() -> void:
	_defs.clear()
	var dir := DirAccess.open(ANIMALS_DIR)
	if dir == null:
		return
	for file in dir.get_files():
		var fname := file.trim_suffix(".remap")
		if fname.ends_with(".tres") or fname.ends_with(".res"):
			var res = load(ANIMALS_DIR + fname)
			if res is AnimalDef:
				_defs.append(res)
	_defs.sort_custom(func(a, b): return a.id < b.id)

func _def() -> AnimalDef:
	if _defs.is_empty():
		return null
	return _defs[_index]

func is_active() -> bool:
	return _active

func cancel() -> void:
	_exit()

# ---------------------------------------------------------------- Input

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_H:
			_toggle()
			get_viewport().set_input_as_handled()
		KEY_F:
			# Đặt con vật đang chọn vào chuồng player đang đứng (không cần chế độ).
			if _place_selected_animal():
				get_viewport().set_input_as_handled()
		KEY_TAB:
			if _active and _defs.size() > 1:
				_index = (_index + 1) % _defs.size()
				_rebuild_ghost()
				get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_KP_ENTER:
			if _active:
				_buy()
				get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			if _active:
				_exit()
				get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_buy()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_exit()
			get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- Buy mode (preview)

func _process(_delta: float) -> void:
	if not _active or _ghost == null:
		return
	var layer := BuildingManager.get_grass_layer()
	if layer == null:
		return
	_ghost.position = layer.get_local_mouse_position()
	_ghost.modulate = VALID_TINT if CurrencyManager.can_afford(_def().price) else INVALID_TINT

func _toggle() -> void:
	if _active:
		_exit()
	else:
		_enter()

func _enter() -> void:
	if _def() == null:
		push_warning("AnimalPlacer: chưa có AnimalDef nào trong " + ANIMALS_DIR)
		return
	if BuildingManager.get_grass_layer() == null:
		return
	BuildingPlacer.cancel()
	RemoveController.cancel()
	_active = true
	_rebuild_ghost()

func _exit() -> void:
	_active = false
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null

func _rebuild_ghost() -> void:
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
	var layer := BuildingManager.get_grass_layer()
	var def := _def()
	if layer == null or def == null or def.scene == null:
		return
	_ghost = def.scene.instantiate() as Node2D
	_ghost.process_mode = Node.PROCESS_MODE_DISABLED
	_ghost.z_index = 100
	layer.add_child(_ghost)

## MUA 1 con loài hiện tại: tốn vàng → +1 item vào túi.
func _buy() -> void:
	var def := _def()
	if def == null:
		return
	if not CurrencyManager.spend(def.price):
		return
	InventoryManager.add_collectable(String(def.id))

# ---------------------------------------------------------------- Place by F

## Đặt con vật ĐANG CHỌN trên hotbar vào chuồng player đang đứng. true nếu đã đặt.
func _place_selected_animal() -> bool:
	var item: ItemDef = ItemRegistry.get_item(ToolManager.selected_item_id)
	if item == null or item.category != ItemDef.Category.ANIMAL:
		return false
	var def := item.animal as AnimalDef
	if def == null:
		return false
	if InventoryManager.get_count(String(item.id)) <= 0:
		return false

	var layer := BuildingManager.get_grass_layer()
	if layer == null or Global.player == null:
		return false
	var player_cell: Vector2i = layer.local_to_map(layer.to_local(Global.player.global_position))
	var pen := BuildingManager.building_at_cell(player_cell) as PlacedBuilding
	if pen == null or not pen.can_accept(def.animal_type):
		return false

	InventoryManager.remove_collectable(String(item.id))
	var animal := def.scene.instantiate() as Node2D
	animal.set_meta("animal_item", String(item.id))
	var agent := animal.get_node_or_null("NavigationAgent2D") as NavigationAgent2D
	if agent != null:
		agent.navigation_layers = pen.pen_nav_layer
	pen.add_child(animal)
	animal.position = pen.random_interior_local()
	var prod := animal.get_node_or_null("ProductionComponent")
	if prod != null and prod.has_method("configure"):
		prod.configure(def)
	var hunger := animal.get_node_or_null("HungerComponent")
	if hunger != null and hunger.has_method("configure"):
		hunger.configure(def)
	pen.add_animal()
	return true
