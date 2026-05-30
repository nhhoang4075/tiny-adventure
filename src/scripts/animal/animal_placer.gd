extends Node

## Chế độ mua & thả động vật (giống build mode).
##   H            : bật/tắt
##   Tab          : đổi loài (gà / bò / ...)
##   Chuột trái   : thả vào chuồng dưới con trỏ (nếu hợp lệ) → trừ vàng
##   Esc / phải   : huỷ
##
## Hợp lệ = chuồng đúng animal_type + còn chỗ (capacity) + đủ vàng.
## Ghost = chính scene con vật (tắt process) tô trắng/đỏ.

const ANIMALS_DIR := "res://resources/animals/"
const VALID_TINT := Color(1, 1, 1, 0.85)
const INVALID_TINT := Color(1.0, 0.4, 0.4, 0.85)

var _defs: Array[AnimalDef] = []
var _index: int = 0
var _active: bool = false
var _ghost: Node2D
var _target_pen: PlacedBuilding
var _valid: bool = false

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
		KEY_TAB:
			if _active and _defs.size() > 1:
				_index = (_index + 1) % _defs.size()
				_rebuild_ghost()
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
			_try_place()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_exit()
			get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- Mode

func _process(_delta: float) -> void:
	if not _active or _ghost == null:
		return
	var layer := BuildingManager.get_grass_layer()
	if layer == null:
		return
	var def := _def()
	var cell: Vector2i = layer.local_to_map(layer.get_local_mouse_position())
	_target_pen = BuildingManager.building_at_cell(cell) as PlacedBuilding
	_valid = _target_pen != null and _target_pen.can_accept(def.animal_type) and CurrencyManager.can_afford(def.price)
	_ghost.position = layer.get_local_mouse_position()
	_ghost.modulate = VALID_TINT if _valid else INVALID_TINT

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
	_active = true
	ToolManager.select_tool(DataTypes.Tools.None)
	_rebuild_ghost()

func _exit() -> void:
	_active = false
	_target_pen = null
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
	_ghost.process_mode = Node.PROCESS_MODE_DISABLED  # ghost không tự đi
	_ghost.z_index = 100
	layer.add_child(_ghost)

func _try_place() -> void:
	if not _valid or _target_pen == null:
		return
	var def := _def()
	if not CurrencyManager.spend(def.price):
		return
	var animal := def.scene.instantiate() as Node2D
	# Gán nav layer của chuồng trước khi vào tree → animal chỉ đi trong chuồng này.
	var agent := animal.get_node_or_null("NavigationAgent2D") as NavigationAgent2D
	if agent != null:
		agent.navigation_layers = _target_pen.pen_nav_layer
	_target_pen.add_child(animal)
	animal.position = _target_pen.random_interior_local()
	# Cấu hình sản xuất theo breed (trứng/sữa, sản lượng).
	var prod := animal.get_node_or_null("ProductionComponent")
	if prod != null and prod.has_method("configure"):
		prod.configure(def)
	_target_pen.add_animal()
