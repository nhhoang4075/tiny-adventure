extends Node

## Điều khiển chế độ xây (build mode).
##   G            : bật/tắt build mode
##   Tab          : đổi loại công trình (gia cầm / gia súc / ...)
##   R            : xoay 90°
##   Chuột trái   : đặt (nếu hợp lệ)
##   Esc / phải   : huỷ build mode
##
## Ghost = chính scene công trình (dựng hàng rào thật) + tắt collision + tô xanh/đỏ.

const DEFS_DIR := "res://resources/buildings/"
const VALID_TINT := Color(1.0, 1.0, 1.0, 0.8)
const INVALID_TINT := Color(1.0, 0.4, 0.4, 0.8)

var _defs: Array[BuildingDef] = []
var _def_index: int = 0
var _active: bool = false
var _rotation: int = 0
var _ghost: Node2D
var _origin: Vector2i
var _valid: bool = false

func _ready() -> void:
	_load_defs()

func _load_defs() -> void:
	_defs.clear()
	var dir := DirAccess.open(DEFS_DIR)
	if dir == null:
		return
	for file in dir.get_files():
		var fname := file.trim_suffix(".remap")
		if fname.ends_with(".tres") or fname.ends_with(".res"):
			var res = load(DEFS_DIR + fname)
			if res is BuildingDef:
				_defs.append(res)
	_defs.sort_custom(func(a, b): return a.id < b.id)

func _def() -> BuildingDef:
	if _defs.is_empty():
		return null
	return _defs[_def_index]

func is_active() -> bool:
	return _active

func cancel() -> void:
	_exit()

# ---------------------------------------------------------------- Input

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_G:
			_toggle()
			get_viewport().set_input_as_handled()
		KEY_R:
			if _active:
				_rotation = (_rotation + 1) % 4
				_rebuild_ghost()
				get_viewport().set_input_as_handled()
		KEY_TAB:
			if _active and _defs.size() > 1:
				_def_index = (_def_index + 1) % _defs.size()
				_rotation = 0
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

# ---------------------------------------------------------------- Build mode

func _process(_delta: float) -> void:
	if not _active or _ghost == null:
		return
	var layer := BuildingManager.get_grass_layer()
	if layer == null:
		return
	_origin = layer.local_to_map(layer.get_local_mouse_position())
	BuildingManager.refresh_objects()
	var cells := _def().footprint_cells(_origin, _rotation)
	_valid = BuildingManager.can_place(cells)
	var ts := Vector2(layer.tile_set.tile_size)
	_ghost.position = layer.map_to_local(_origin) - ts * 0.5
	_ghost.modulate = VALID_TINT if _valid else INVALID_TINT

func _toggle() -> void:
	if _active:
		_exit()
	else:
		_enter()

func _enter() -> void:
	if _def() == null:
		push_warning("BuildingPlacer: chưa có BuildingDef nào trong " + DEFS_DIR)
		return
	if BuildingManager.get_grass_layer() == null:
		return
	AnimalPlacer.cancel()  # không để 2 chế độ cùng bật
	RemoveController.cancel()
	_active = true
	_rotation = 0
	ToolManager.select_tool(DataTypes.Tools.None)  # tránh click đặt vô tình chặt/cuốc
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
	_ghost.z_index = 100
	layer.add_child(_ghost)
	if _ghost is PlacedBuilding:
		_ghost.setup(def, _rotation, Vector2(layer.tile_set.tile_size))
		_ghost.set_ghost(true)

func _try_place() -> void:
	var def := _def()
	if def == null or def.scene == null:
		return
	BuildingManager.refresh_objects()
	var cells := def.footprint_cells(_origin, _rotation)
	if not BuildingManager.can_place(cells):
		return
	var layer := BuildingManager.get_grass_layer()
	var instance := def.scene.instantiate() as Node2D
	layer.add_child(instance)
	instance.position = layer.map_to_local(_origin) - Vector2(layer.tile_set.tile_size) * 0.5
	if instance is PlacedBuilding:
		instance.setup(def, _rotation, Vector2(layer.tile_set.tile_size))
		instance.build_navigation(def)
	BuildingManager.register(cells, instance.get_instance_id())
	_exit()
