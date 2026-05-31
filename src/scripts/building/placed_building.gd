class_name PlacedBuilding
extends Node2D

## Công trình đã đặt. Hàng rào dựng procedural bằng terrain autotile (chừa 1 ô cổng
## theo hướng xoay) để hỗ trợ xoay 4 hướng. Khu cho ăn (nếu có) là scene riêng
## (FeedStation) được instance vào góc nội thất — art/collision/vùng-cho-ăn chỉnh
## trong editor, không hardcode ở đây.

const FILL := Color(0.55, 0.35, 0.18, 0.55)
const BORDER := Color(0.30, 0.18, 0.08, 0.95)
## Nới vùng khoét nav quanh khu cho ăn (xấp xỉ bán kính animal) để chúng không cấn.
const NAV_CARVE_PAD := 14.0

const HIGHLIGHT_SHADER := preload("res://scenes/objects/object_fx.gdshader")

@onready var _fence: TileMapLayer = $Fence

var building_def: BuildingDef
var pen_nav_layer: int = 0
var animal_count: int = 0
var _hl_mat: ShaderMaterial

var _cell_size: Vector2 = Vector2(16, 16)
var _grid_size: Vector2i = Vector2i(4, 3)
var _use_placeholder: bool = true
var _feed_station: Node2D

func setup(def: BuildingDef, rot: int, cell_size: Vector2) -> void:
	building_def = def
	_cell_size = cell_size
	_grid_size = def.rotated_size(rot)
	if def.fence_terrain >= 0 and _fence != null:
		_use_placeholder = false
		_build_fence(def, rot)
	else:
		_use_placeholder = true
	_spawn_feed_station(def)
	queue_redraw()

## Chế độ ghost: tắt collision (xem trước) — cả hàng rào lẫn khu cho ăn.
func set_ghost(on: bool) -> void:
	if _fence != null:
		_fence.collision_enabled = not on
	if _feed_station != null and _feed_station.has_method("set_ghost"):
		_feed_station.set_ghost(on)

## Instance scene khu cho ăn vào góc trên-trái nội thất (cell (1,1)) — tránh giữa các
## cạnh nơi có cổng. Scene tự lo art/collision/vùng-cho-ăn.
func _spawn_feed_station(def: BuildingDef) -> void:
	if def.feed_station_scene == null:
		return
	if _grid_size.x < 3 or _grid_size.y < 3:
		return  # không có nội thất
	_feed_station = def.feed_station_scene.instantiate() as Node2D
	_feed_station.position = _cell_size  # cell (1,1) top-left
	add_child(_feed_station)

## Sinh NavigationRegion2D phủ nội thất (cho animal đi). Chỉ gọi khi đặt thật.
func build_navigation(def: BuildingDef) -> void:
	var w := _grid_size.x
	var h := _grid_size.y
	if w < 3 or h < 3:
		return  # không có nội thất
	var interior := _interior_rect()
	var x0 := interior.position.x
	var y0 := interior.position.y
	var x1 := interior.end.x
	var y1 := interior.end.y

	var poly := NavigationPolygon.new()
	var hole := _feed_station_hole(interior)
	var hx: float = hole.position.x + hole.size.x
	var hy: float = hole.position.y + hole.size.y
	if hole.size.x <= 0.0 or hole.size.y <= 0.0 or hx >= x1 or hy >= y1:
		# Không có khu cho ăn (hoặc nó quá lớn) → nav hình chữ nhật đầy.
		poly.vertices = PackedVector2Array([
			Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)
		])
		poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	else:
		# Khoét góc trên-trái (chứa khu cho ăn) → vùng đi lại hình chữ L (2 quad).
		poly.vertices = PackedVector2Array([
			Vector2(hx, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(hx, y1),  # dải phải
			Vector2(x0, hy), Vector2(hx, hy), Vector2(hx, y1), Vector2(x0, y1),  # dải dưới-trái
		])
		poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
		poly.add_polygon(PackedInt32Array([4, 5, 6, 7]))

	# Mỗi chuồng 1 nav layer riêng → animal chỉ đi trong đúng chuồng của nó.
	pen_nav_layer = BuildingManager.allocate_nav_layer()
	var nav := NavigationRegion2D.new()
	nav.navigation_layers = pen_nav_layer
	nav.navigation_polygon = poly
	add_child(nav)

## Hình chữ nhật nội thất (pen-local) — vùng đi lại trước khi khoét khu cho ăn.
func _interior_rect() -> Rect2:
	var ts := _cell_size
	return Rect2(ts.x, ts.y, (_grid_size.x - 1) * ts.x - ts.x, (_grid_size.y - 1) * ts.y - ts.y)

## Vùng (pen-local) cần khoét khỏi nav = footprint khu cho ăn nới theo bán kính
## agent, clamp vào nội thất (neo ở góc trên-trái). Rỗng nếu không có khu cho ăn.
func _feed_station_hole(interior: Rect2) -> Rect2:
	if _feed_station == null or not _feed_station.has_method("get_blocked_rect"):
		return Rect2()
	var local: Rect2 = _feed_station.get_blocked_rect()
	if local.size == Vector2.ZERO:
		return Rect2()
	var pen_rect := Rect2(_feed_station.position + local.position, local.size).grow(NAV_CARVE_PAD)
	return pen_rect.intersection(interior)

## Chuồng có nhận thêm animal loại này không (đúng loại + còn chỗ).
func can_accept(atype: StringName) -> bool:
	return building_def != null and building_def.animal_type == atype and animal_count < building_def.capacity

func add_animal() -> void:
	animal_count += 1

## Highlight chuồng = phủ trắng (sáng dần) lên CHÍNH các tile hàng rào — theo đúng
## hình hàng rào, không phải khung bao quanh footprint. amount 0 = tắt.
func set_highlight(on: bool, amount: float = 0.0) -> void:
	if _fence == null:
		return
	if on:
		if _hl_mat == null:
			_hl_mat = ShaderMaterial.new()
			_hl_mat.shader = HIGHLIGHT_SHADER
		_hl_mat.set_shader_parameter("highlight_amount", amount)
		if _fence.material != _hl_mat:
			_fence.material = _hl_mat
	elif _fence.material == _hl_mat:
		_fence.material = null

## Rect footprint trong toạ độ layer cha (Grass).
func footprint_local_rect() -> Rect2:
	return Rect2(position, Vector2(_grid_size) * _cell_size)

## Danh sách con vật trong chuồng (con vật là CharacterBody2D con trực tiếp).
func get_animals() -> Array:
	var result: Array = []
	for child in get_children():
		if child is CharacterBody2D:
			result.append(child)
	return result

## Tâm nội thất (local) để đặt animal.
func interior_center_local() -> Vector2:
	return Vector2(_grid_size) * _cell_size * 0.5

## Điểm ngẫu nhiên trong nội thất, chừa margin cách rìa, và TRÁNH khu cho ăn (vùng đã
## khoét khỏi nav) — nếu rơi vào đó animal sẽ ở ngoài navmesh và bị kẹt. Lấy mẫu lại
## tối đa vài lần; nếu vẫn trúng thì lùi về góc đối diện khu cho ăn (luôn nằm trong nav).
func random_interior_local() -> Vector2:
	var interior := _interior_rect()
	if interior.size.x <= 0.0 or interior.size.y <= 0.0:
		return Vector2(_grid_size) * _cell_size * 0.5  # chuồng quá nhỏ → về tâm
	var m := _cell_size.x * 0.6  # margin cách rìa nội thất
	var area := Rect2(interior.position + Vector2(m, m), interior.size - Vector2(m, m) * 2.0)
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		area = interior
	var hole := _feed_station_hole(interior)
	for _i in 12:
		var p := Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
		if hole.size == Vector2.ZERO or not hole.has_point(p):
			return p
	# Khu cho ăn ở góc trên-trái → lùi về phía dưới-phải (chắc chắn ngoài hố, trong nav).
	return Vector2(area.end.x, area.end.y) - area.size * 0.2

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
