extends Node

## Hệ thống spawn tài nguyên data-driven, kế thừa TreeRockSpawner cũ.
##
## - Định nghĩa tài nguyên: thả file .tres (ResourceDef) vào res://resources/spawnable/
## - Vùng spawn: đặt node SpawnZone (Area2D + CollisionPolygon2D) vào scene
## - Auto top-up: mỗi ngày, nếu số lượng < max_count thì sinh thêm 1 lượt
##   (random per_round_min..max), vào ô đất hợp lệ (tránh nước/chuồng/rìa, theo zone).

const DEFS_DIR := "res://resources/spawnable/"
## Số tile tối thiểu cách bờ nước / rìa đảo. Ô grass có hàng xóm không-grass trong
## bán kính này sẽ bị loại → cây/đá không tràn ra biển/hồ.
const SHORE_MARGIN: int = 2
const SPAWN_SEARCH_ATTEMPTS: int = 50
const NO_CELL := Vector2i(-2147483648, -2147483648)

## Đặt false để tắt log + phím debug P sau khi test xong.
var debug_mode: bool = true

var _grass_layer: TileMapLayer
var _water_layer: TileMapLayer
var _farmland_layer: TileMapLayer
var _trees_layer: TileMapLayer
var _rocks_layer: TileMapLayer
var _base_layer: TileMapLayer
var _dynamic_parent: Node2D

var _defs: Dictionary = {}            # id(StringName) -> ResourceDef
var _defs_by_scene: Dictionary = {}   # scene_path(String) -> ResourceDef
var _zoned_ids: Dictionary = {}       # id(StringName) -> true nếu bị giới hạn theo zone
var _excluded_rects: Array[Rect2] = []
var _valid_cells: Array[Vector2i] = []
var _is_ready: bool = false

func _ready() -> void:
	_load_defs()
	DayNightCycleManager.day_tick.connect(_on_day_tick)
	_try_setup.call_deferred()

# ---------------------------------------------------------------- Resource defs

func _load_defs() -> void:
	_defs.clear()
	_defs_by_scene.clear()
	var dir := DirAccess.open(DEFS_DIR)
	if dir == null:
		push_warning("ResourceSpawnManager: không mở được " + DEFS_DIR)
		return
	for file in dir.get_files():
		var fname := file.trim_suffix(".remap")
		if not (fname.ends_with(".tres") or fname.ends_with(".res")):
			continue
		var res = load(DEFS_DIR + fname)
		if res is ResourceDef and res.id != StringName(""):
			_defs[res.id] = res
			if res.scene != null:
				_defs_by_scene[res.scene.resource_path] = res
	if debug_mode:
		print("ResourceSpawnManager: loaded ", _defs.size(), " resource defs: ", _defs.keys())

# ---------------------------------------------------------------- Scene setup

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
	_water_layer = tile_map.find_child("Water", true, false) as TileMapLayer
	_farmland_layer = tile_map.find_child("FarmLand", true, false) as TileMapLayer
	_trees_layer = tile_map.find_child("Trees", true, false) as TileMapLayer
	_rocks_layer = tile_map.find_child("Rocks", true, false) as TileMapLayer
	_base_layer = _grass_layer
	if _base_layer == null:
		return
	_dynamic_parent = _trees_layer if _trees_layer != null else _base_layer
	_collect_excluded_rects(root)
	_compute_valid_cells()
	_index_zoned_ids()
	_is_ready = true
	if debug_mode:
		print("ResourceSpawnManager setup OK | valid_cells=", _valid_cells.size(),
			" excluded=", _excluded_rects.size(), " zones=", get_tree().get_nodes_in_group("spawn_zones").size())

func _index_zoned_ids() -> void:
	_zoned_ids.clear()
	for zone in get_tree().get_nodes_in_group("spawn_zones"):
		for rid in (zone as SpawnZone).resource_ids:
			_zoned_ids[rid] = true

func _collect_excluded_rects(root: Node) -> void:
	_excluded_rects.clear()
	for node in root.find_children("*", "NavigationRegion2D", true, false):
		var nav := node as NavigationRegion2D
		if nav == null or nav.navigation_polygon == null:
			continue
		var rect := _polygon_world_bounds(nav)
		if rect.size != Vector2.ZERO:
			_excluded_rects.append(rect)

func _polygon_world_bounds(nav: NavigationRegion2D) -> Rect2:
	var poly := nav.navigation_polygon
	if poly == null or poly.get_outline_count() == 0:
		return Rect2()
	var initialized := false
	var rect := Rect2()
	for i in poly.get_outline_count():
		for v in poly.get_outline(i):
			var world_v := nav.to_global(v)
			if not initialized:
				rect = Rect2(world_v, Vector2.ZERO)
				initialized = true
			else:
				rect = rect.expand(world_v)
	return rect

# ---------------------------------------------------------------- Valid cells

func _compute_valid_cells() -> void:
	_valid_cells.clear()
	# Đất liền = layer Grass (hòn đảo). Ground/Undergrowth có ô đặt ngoài đảo nên không dùng.
	var grass_cells: Array[Vector2i] = _grass_layer.get_used_cells()
	if grass_cells.is_empty():
		return
	var grass_set: Dictionary = {}
	for c in grass_cells:
		grass_set[c] = true
	var c_shore := 0
	var c_farm := 0
	var c_excl := 0
	for cell in grass_cells:
		# Loại ô gần bờ nước / rìa đảo: mọi ô trong bán kính SHORE_MARGIN phải là grass.
		if not _is_inland(cell, grass_set):
			c_shore += 1
			continue
		if _farmland_layer and _farmland_layer.get_cell_source_id(cell) != -1:
			c_farm += 1
			continue
		var world_pos := _base_layer.to_global(_base_layer.map_to_local(cell))
		if _is_in_excluded_rect(world_pos):
			c_excl += 1
			continue
		_valid_cells.append(cell)
	if debug_mode:
		print("  _compute_valid_cells: grass=", grass_cells.size(),
			" | rejected shore=", c_shore, " farm=", c_farm, " excluded=", c_excl,
			" => valid=", _valid_cells.size())

## Ô được coi là "trong đất liền" nếu mọi ô lân cận trong bán kính SHORE_MARGIN đều là grass.
func _is_inland(cell: Vector2i, grass_set: Dictionary) -> bool:
	for dx in range(-SHORE_MARGIN, SHORE_MARGIN + 1):
		for dy in range(-SHORE_MARGIN, SHORE_MARGIN + 1):
			if not grass_set.has(cell + Vector2i(dx, dy)):
				return false
	return true

func _is_in_excluded_rect(world_pos: Vector2) -> bool:
	for rect in _excluded_rects:
		if rect.has_point(world_pos):
			return true
	return false

# ---------------------------------------------------------------- Auto top-up

## Mỗi ngày: với từng loại, nếu chưa đạt max_count thì sinh thêm 1 lượt
## (random per_round_min..per_round_max, không vượt cap).
func _on_day_tick(_day: int) -> void:
	if not _is_ready:
		_try_setup()
	if not _is_ready:
		return
	for def in _defs.values():
		_top_up(def)

func _top_up(def: ResourceDef) -> void:
	var alive := _count_alive(def)
	if alive >= def.max_count:
		return
	var want := randi_range(def.per_round_min, def.per_round_max)
	var room := def.max_count - alive
	var n: int = min(want, room)
	for i in n:
		_spawn(def)
	if debug_mode:
		print("ResourceSpawnManager: top-up ", def.id, " alive=", alive, "/", def.max_count, " +", n)

## Đếm số instance đang sống của loại này trên toàn map (gốc + đã spawn).
func _count_alive(def: ResourceDef) -> int:
	var path := def.scene.resource_path
	var count := 0
	var seen: Dictionary = {}
	for layer in [_trees_layer, _rocks_layer, _dynamic_parent]:
		if layer == null:
			continue
		for child in layer.get_children(true):
			var id: int = child.get_instance_id()
			if seen.has(id):
				continue
			seen[id] = true
			if child is Node2D and child.scene_file_path == path:
				count += 1
	return count

func _spawn(def: ResourceDef) -> void:
	if _valid_cells.is_empty() or _dynamic_parent == null or def.scene == null:
		if debug_mode:
			print("ResourceSpawnManager: cannot spawn — valid_cells=", _valid_cells.size())
		return
	var zones := _zones_for(def.id)
	# Nếu bị giới hạn theo zone, chỉ giữ các zone còn chỗ (alive < max_alive).
	if not zones.is_empty():
		var available: Array = []
		for zone in zones:
			var z := zone as SpawnZone
			if z.max_alive < 0 or _count_alive_in_zone(def, z) < z.max_alive:
				available.append(zone)
		if available.is_empty():
			if debug_mode:
				print("ResourceSpawnManager: ", def.id, " — tất cả zone đã đạt max_alive, bỏ qua")
			return
		zones = available
	var cell := _find_free_cell(def, zones)
	if cell == NO_CELL:
		if debug_mode:
			print("ResourceSpawnManager: cannot spawn ", def.id, " — no free cell")
		return
	var instance := def.scene.instantiate() as Node2D
	_dynamic_parent.add_child(instance)
	# Đặt bằng local position trong layer — giống hệt cách Godot đặt scene-tile gốc,
	# tránh lỗi nhân đôi scale khi set global_position.
	instance.position = _dynamic_parent.map_to_local(cell)
	if debug_mode:
		print("ResourceSpawnManager: spawned ", def.id, " at cell ", cell,
			" local ", instance.position, " global ", instance.global_position)

func _find_free_cell(def: ResourceDef, zones: Array) -> Vector2i:
	var attempts := SPAWN_SEARCH_ATTEMPTS
	while attempts > 0:
		var cell: Vector2i = _valid_cells[randi() % _valid_cells.size()]
		if BuildingManager.is_occupied(cell):
			attempts -= 1
			continue  # tránh spawn vào chuồng (rào/nội thất)
		var world_pos := _base_layer.to_global(_base_layer.map_to_local(cell))
		if _cell_ok(world_pos, def, zones):
			return cell
		attempts -= 1
	return NO_CELL

## Đếm số tài nguyên cùng loại (cùng scene) đang sống bên trong một zone.
func _count_alive_in_zone(def: ResourceDef, zone: SpawnZone) -> int:
	var path := def.scene.resource_path
	var count := 0
	var seen: Dictionary = {}
	for layer in [_trees_layer, _rocks_layer, _dynamic_parent]:
		if layer == null:
			continue
		for child in layer.get_children(true):
			var id: int = child.get_instance_id()
			if seen.has(id):
				continue
			seen[id] = true
			if child is Node2D and child.scene_file_path == path and zone.contains_point(child.global_position):
				count += 1
	return count

## Trả về danh sách zone giới hạn loại này; rỗng nghĩa là spawn toàn đảo.
func _zones_for(resource_id: StringName) -> Array:
	if not _zoned_ids.has(resource_id):
		return []
	var result: Array = []
	for zone in get_tree().get_nodes_in_group("spawn_zones"):
		if (zone as SpawnZone).allows(resource_id):
			result.append(zone)
	return result

func _cell_ok(world_pos: Vector2, def: ResourceDef, zones: Array) -> bool:
	# Nếu loại này bị giới hạn theo zone, ô phải nằm trong một zone cho phép.
	if not zones.is_empty():
		var inside := false
		for zone in zones:
			if (zone as SpawnZone).contains_point(world_pos):
				inside = true
				break
		if not inside:
			return false
	# Khoảng cách tối thiểu tới object đang sống.
	for layer in [_trees_layer, _rocks_layer, _dynamic_parent]:
		if layer == null:
			continue
		for child in layer.get_children(true):
			if child is Node2D and child.global_position.distance_to(world_pos) < def.min_spacing:
				return false
	return true

# ---------------------------------------------------------------- Debug

func _unhandled_key_input(event: InputEvent) -> void:
	if not debug_mode:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		_try_setup()
		print("=== ResourceSpawnManager DEBUG ===")
		print("  is_ready: ", _is_ready, " | valid_cells: ", _valid_cells.size())
		print("  defs: ", _defs.keys(), " | zoned_ids: ", _zoned_ids.keys())
		print("  zones: ", get_tree().get_nodes_in_group("spawn_zones").size())
		print("  current_day: ", DayNightCycleManager.current_day)
		for def in _defs.values():
			print("  ", def.id, " alive=", _count_alive(def), "/", def.max_count)
		print("  Running one top-up round (simulate a day)...")
		_on_day_tick(DayNightCycleManager.current_day)
		print("==================================")
