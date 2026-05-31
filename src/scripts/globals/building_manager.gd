extends Node

## Quản lý ô đã bị công trình chiếm + kiểm tra ô có xây được không.
## Ô xây được = có Grass (đất liền đảo) và không bị công trình khác chiếm.

var _grass_layer: TileMapLayer
var _trees_layer: TileMapLayer
var _rocks_layer: TileMapLayer
var _grass_set: Dictionary = {}          # cell -> true
var _occupied: Dictionary = {}           # cell -> instance_id của công trình
var _building_cells: Dictionary = {}     # instance_id -> Array[Vector2i] (để phá sạch)
var _object_cells: Dictionary = {}       # cell -> true (cây/đá đang sống)
var _is_ready: bool = false

func _try_setup() -> void:
	if _is_ready:
		return
	var root := get_tree().current_scene
	if root == null:
		return
	var tile_map: Node = root.find_child("TileMap", true, false)
	if tile_map == null:
		return
	_grass_layer = tile_map.find_child("Grass", true, false) as TileMapLayer
	if _grass_layer == null:
		return
	_trees_layer = tile_map.find_child("Trees", true, false) as TileMapLayer
	_rocks_layer = tile_map.find_child("Rocks", true, false) as TileMapLayer
	_grass_set.clear()
	for cell in _grass_layer.get_used_cells():
		_grass_set[cell] = true
	_is_ready = true

## Quét lại các ô có VẬT CẢN xây (cây/đá/gốc — group "build_obstacle").
## Dựa trên GROUP chứ không quét cả layer → đồ rớt / vòng progress / highlight (dù
## nằm trong layer nào) cũng không bị tính là vật cản.
const OBSTACLE_GROUP := "build_obstacle"

func refresh_objects() -> void:
	if not _is_ready:
		_try_setup()
	if not _is_ready:
		return
	_object_cells.clear()
	for node in get_tree().get_nodes_in_group(OBSTACLE_GROUP):
		if node is Node2D:
			var cell: Vector2i = _grass_layer.local_to_map(_grass_layer.to_local(node.global_position))
			_object_cells[cell] = true

func get_grass_layer() -> TileMapLayer:
	if not _is_ready:
		_try_setup()
	return _grass_layer

## Layer chứa cây/đá/stump (y-sort) — nơi nên add item rớt để xếp lớp đúng.
func get_object_layer() -> TileMapLayer:
	if not _is_ready:
		_try_setup()
	return _trees_layer if _trees_layer != null else _grass_layer

func can_build_cell(cell: Vector2i) -> bool:
	if not _is_ready:
		_try_setup()
	return _grass_set.has(cell) and not _occupied.has(cell) and not _object_cells.has(cell)

func can_place(cells: Array[Vector2i]) -> bool:
	if not _is_ready:
		_try_setup()
	if cells.is_empty():
		return false
	for c in cells:
		if not can_build_cell(c):
			return false
	return true

func register(cells: Array[Vector2i], building_id: int) -> void:
	for c in cells:
		_occupied[c] = building_id
	_building_cells[building_id] = cells.duplicate()

func unregister(cells: Array[Vector2i]) -> void:
	for c in cells:
		_occupied.erase(c)

## Gỡ đăng ký toàn bộ ô của 1 công trình (khi phá) — không cần biết cells từ ngoài.
func remove_building(building_id: int) -> void:
	var cells: Array = _building_cells.get(building_id, [])
	for c in cells:
		_occupied.erase(c)
	_building_cells.erase(building_id)

## Ô có bị công trình chiếm không (cả footprint: rào + nội thất).
func is_occupied(cell: Vector2i) -> bool:
	return _occupied.has(cell)

## Ô là đất đi/nhặt được (có grass, không bị chuồng chiếm). Dùng cho rớt đồ ngoài trời.
func is_land_cell(cell: Vector2i) -> bool:
	if not _is_ready:
		_try_setup()
	return _grass_set.has(cell) and not _occupied.has(cell)

## Ô có phải đất (grass) không, KHÔNG quan tâm chuồng chiếm. Dùng cho đồ rớt trong chuồng.
func is_grass_cell(cell: Vector2i) -> bool:
	if not _is_ready:
		_try_setup()
	return _grass_set.has(cell)

## Trả về PlacedBuilding tại ô (nếu có).
func building_at_cell(cell: Vector2i) -> Node:
	if _occupied.has(cell):
		return instance_from_id(_occupied[cell])
	return null

## Cấp 1 nav layer (bitmask) duy nhất cho mỗi chuồng. Tránh bit 0,1 (chuồng mặc định).
var _next_nav_bit: int = 2

func allocate_nav_layer() -> int:
	var value := 1 << _next_nav_bit
	_next_nav_bit += 1
	if _next_nav_bit > 31:
		_next_nav_bit = 2
	return value
