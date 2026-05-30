class_name PlacedBuilding
extends Node2D

## Công trình đã đặt. Nếu BuildingDef.fence_terrain >= 0 thì tự dựng hàng rào quanh
## chu vi footprint bằng terrain autotile (chừa 1 ô cổng theo hướng). Ngược lại vẽ
## khung placeholder.

const FILL := Color(0.55, 0.35, 0.18, 0.55)
const BORDER := Color(0.30, 0.18, 0.08, 0.95)

@onready var _fence: TileMapLayer = $Fence

var building_def: BuildingDef
var pen_nav_layer: int = 0
var animal_count: int = 0

var _cell_size: Vector2 = Vector2(16, 16)
var _grid_size: Vector2i = Vector2i(4, 3)
var _use_placeholder: bool = true

func setup(def: BuildingDef, rot: int, cell_size: Vector2) -> void:
	building_def = def
	_cell_size = cell_size
	_grid_size = def.rotated_size(rot)
	if def.fence_terrain >= 0 and _fence != null:
		_use_placeholder = false
		_build_fence(def, rot)
	else:
		_use_placeholder = true
	queue_redraw()

## Chế độ ghost: tắt collision (chỉ để xem trước).
func set_ghost(on: bool) -> void:
	if _fence != null:
		_fence.collision_enabled = not on

## Sinh NavigationRegion2D phủ nội thất (cho animal đi). Chỉ gọi khi đặt thật.
func build_navigation(def: BuildingDef) -> void:
	var w := _grid_size.x
	var h := _grid_size.y
	if w < 3 or h < 3:
		return  # không có nội thất
	var ts := _cell_size
	var x0 := ts.x
	var y0 := ts.y
	var x1 := (w - 1) * ts.x
	var y1 := (h - 1) * ts.y
	var poly := NavigationPolygon.new()
	poly.vertices = PackedVector2Array([
		Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)
	])
	poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	# Mỗi chuồng 1 nav layer riêng → animal chỉ đi trong đúng chuồng của nó.
	pen_nav_layer = BuildingManager.allocate_nav_layer()
	var nav := NavigationRegion2D.new()
	nav.navigation_layers = pen_nav_layer
	nav.navigation_polygon = poly
	add_child(nav)

## Chuồng có nhận thêm animal loại này không (đúng loại + còn chỗ).
func can_accept(atype: StringName) -> bool:
	return building_def != null and building_def.animal_type == atype and animal_count < building_def.capacity

func add_animal() -> void:
	animal_count += 1

## Tâm nội thất (local) để đặt animal.
func interior_center_local() -> Vector2:
	return Vector2(_grid_size) * _cell_size * 0.5

## Điểm ngẫu nhiên trong nội thất, chừa margin cách rìa — tránh spawn sát hàng rào
## và tránh 2 animal chồng khít gây văng ra ngoài.
func random_interior_local() -> Vector2:
	var ts := _cell_size
	var m := ts.x * 0.6  # margin cách rìa nội thất
	var x_min := ts.x + m
	var x_max := (_grid_size.x - 1) * ts.x - m
	var y_min := ts.y + m
	var y_max := (_grid_size.y - 1) * ts.y - m
	if x_min > x_max or y_min > y_max:
		return Vector2(_grid_size) * ts * 0.5  # chuồng quá nhỏ → về tâm
	return Vector2(randf_range(x_min, x_max), randf_range(y_min, y_max))

func _build_fence(def: BuildingDef, rot: int) -> void:
	var w := _grid_size.x
	var h := _grid_size.y
	var gate := _gate_cell(w, h, rot)
	var cells: Array[Vector2i] = []
	for x in w:
		for y in h:
			if x == 0 or x == w - 1 or y == 0 or y == h - 1:
				var c := Vector2i(x, y)
				if c != gate:
					cells.append(c)
	_fence.clear()
	_fence.set_cells_terrain_connect(cells, def.fence_terrain_set, def.fence_terrain)

## Ô cổng (bỏ trống) theo hướng xoay.
func _gate_cell(w: int, h: int, rot: int) -> Vector2i:
	match rot:
		0: return Vector2i(w / 2, h - 1)   # cổng cạnh dưới
		1: return Vector2i(0, h / 2)       # cạnh trái
		2: return Vector2i(w / 2, 0)       # cạnh trên
		_: return Vector2i(w - 1, h / 2)   # cạnh phải

func _draw() -> void:
	if not _use_placeholder:
		return
	var rect := Rect2(Vector2.ZERO, Vector2(_grid_size) * _cell_size)
	draw_rect(rect, FILL, true)
	draw_rect(rect, BORDER, false, 2.0)
