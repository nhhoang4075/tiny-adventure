extends Node

## Tương tác PHÁ (giữ F) + HIGHLIGHT mục tiêu.
##
## Dò mục tiêu bằng VÒNG TRÒN quanh player (bắt được cả khi đứng sát) + chọn gần nhất,
## nên không bị mất target khi tới quá gần.
##
## HIGHLIGHT (luôn hiện hộp viền quanh thứ sẽ bị tác động):
##   xanh = đặt vật nuôi được, vàng = tool sẽ tác động, đỏ = giữ-F sẽ phá.
## PHÁ: giữ F → vòng progress đầy sau HOLD_DURATION → phá. Thả sớm = huỷ.
##   Khi đang giữ F, target được KHOÁ (vật di chuyển vẫn theo, không nhảy sang chuồng).
##   Ưu tiên: tool/seed/animal có việc thì nhường, không phá.

const RING_SHEET := preload("res://assets/Cute_Fantasy_UI/UI/Loading_Icon.png")
const RING_HFRAMES := 16
const RING_VFRAMES := 4
const HOLD_DURATION := 1.2

const TOOL_HIT_LAYER := 8    # ToolHitComponent (cây/đá/crop nhận tool)
const ANIMAL_LAYER := 64     # CharacterBody2D vật nuôi
const INTERACT_RADIUS := 48.0  # bán kính dò (world px) ~1.5 ô

var _overlay: Node2D
var _ring: Sprite2D
var _highlighter: TargetHighlighter
var _target: Node2D
var _hold: float = 0.0
var _crops_node: Node
var _farm_layer: TileMapLayer
var _ground_layer: TileMapLayer

func is_active() -> bool:
	return _target != null

func cancel() -> void:
	_reset_ring()

func _process(delta: float) -> void:
	_ensure_overlay()
	_update_highlight()

	if Global.player == null or BuildingPlacer.is_active() or AnimalPlacer.is_active():
		_reset_ring()
		return
	if not Input.is_physical_key_pressed(KEY_F) or _selected_has_target():
		_reset_ring()
		return

	# Khoá target: giữ nguyên đối tượng đang phá nếu còn hợp lệ; chỉ chọn mới khi mất.
	if _target == null or not is_instance_valid(_target):
		_target = _resolve_demolish_target()
		_hold = 0.0
		if _ring != null:
			_ring.frame = 0
	if _target == null:
		_reset_ring()
		return
	if _ring != null:
		_ring.visible = true
		_ring.global_position = _ring_anchor(_target) + Vector2(0, -20)
		_hold += delta
		_ring.frame = clampi(int(_hold / HOLD_DURATION * (RING_HFRAMES - 1)), 0, RING_HFRAMES - 1)
	if _hold >= HOLD_DURATION:
		var t := _target
		_reset_ring()
		_demolish(t)

# ---------------------------------------------------------------- Overlay

func _ensure_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		return
	var grass := BuildingManager.get_grass_layer()
	if grass == null:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	_overlay = scene.get_node_or_null("Overlay") as Node2D
	if _overlay == null:
		_overlay = Node2D.new()
		_overlay.name = "Overlay"
		_overlay.z_index = 150
		_overlay.z_as_relative = false
		scene.add_child(_overlay)

	_ring = Sprite2D.new()
	_ring.texture = RING_SHEET
	_ring.hframes = RING_HFRAMES
	_ring.vframes = RING_VFRAMES
	_ring.z_index = 160
	_ring.z_as_relative = false
	_ring.visible = false
	_overlay.add_child(_ring)

	_highlighter = TargetHighlighter.new()
	_overlay.add_child(_highlighter)

func _reset_ring() -> void:
	_target = null
	_hold = 0.0
	if _ring != null:
		_ring.visible = false

func _ring_anchor(target: Node2D) -> Vector2:
	if target is PlacedBuilding:
		return target.to_global(target.interior_center_local())
	return target.global_position

# ---------------------------------------------------------------- Highlight (Phase 3)

func _update_highlight() -> void:
	if _highlighter == null:
		return
	# Mỗi frame: xoá hết rồi dựng lại đúng những gì cần (rect + outline có thể cùng lúc).
	_highlighter.clear()
	if Global.player == null or BuildingPlacer.is_active() or AnimalPlacer.is_active():
		return
	var grass := BuildingManager.get_grass_layer()
	if grass == null:
		return

	# (1) Cầm item con vật + đứng trong chuồng hợp lệ → highlight chuồng (xanh).
	var item: ItemDef = ItemRegistry.get_item(ToolManager.selected_item_id)
	if item != null and item.category == ItemDef.Category.ANIMAL:
		var def := item.animal as AnimalDef
		var pcell: Vector2i = grass.local_to_map(Global.player.global_position / Global.player.global_scale)
		var pen := BuildingManager.building_at_cell(pcell) as PlacedBuilding
		if def != null and pen != null and pen.can_accept(def.animal_type) and InventoryManager.get_count(String(item.id)) > 0:
			_highlighter.show_pen(pen)
		return

	# (2) Tool/seed sẽ tác động → highlight mục tiêu (vàng).
	if _selected_has_target():
		_show_tool_highlight(grass)
		return

	# (3) Còn lại → preview mục tiêu PHÁ (đỏ).
	var t := _resolve_demolish_target()
	if t != null and is_instance_valid(t):
		if t is PlacedBuilding:
			_highlighter.show_pen(t)
		else:
			# Vật nuôi / cây trồng → viền trắng theo đúng hình sprite.
			_highlighter.show_object(t)

func _show_tool_highlight(grass: TileMapLayer) -> void:
	match ToolManager.selected_tool:
		DataTypes.Tools.WateringCan:
			# Chỉ viền các cây trong vùng tưới 3x3 (không vẽ ô vuông).
			_highlighter.show_objects(_crops_in_area(_player_front_cell(), 1))
		DataTypes.Tools.Hoe, DataTypes.Tools.Seed:
			# Mục tiêu gắn với 1 ô tile → phủ 1 lớp trắng.
			_highlighter.show_fill(_cell_local_rect(grass, _player_front_cell()))
		DataTypes.Tools.Axe, DataTypes.Tools.Pickaxe:
			var node := _tool_target_in_front()
			if node != null:
				_highlighter.show_object(node)  # viền theo hình cây/đá

func _cell_local_rect(grass: TileMapLayer, cell: Vector2i) -> Rect2:
	var center: Vector2 = grass.map_to_local(cell)
	return Rect2(center - Vector2(8, 8), Vector2(16, 16))

# ---------------------------------------------------------------- Targeting (vòng tròn)

func _player_front_cell() -> Vector2i:
	var layer := BuildingManager.get_grass_layer()
	var pp: Vector2 = Global.player.global_position / Global.player.global_scale
	var pcell: Vector2i = layer.local_to_map(pp)
	var f: Vector2 = Global.player.sprite_direction
	return pcell + Vector2i(roundi(f.x), roundi(f.y))

func _space() -> PhysicsDirectSpaceState2D:
	return Global.player.get_world_2d().direct_space_state

func _circle_query(mask: int, with_areas: bool) -> Array:
	var shape := CircleShape2D.new()
	shape.radius = INTERACT_RADIUS
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, Global.player.global_position)
	params.collision_mask = mask
	params.collide_with_areas = with_areas
	params.collide_with_bodies = not with_areas
	return _space().intersect_shape(params, 16)

func _farmland_layer() -> TileMapLayer:
	if _farm_layer == null or not is_instance_valid(_farm_layer):
		var scene := get_tree().current_scene
		if scene != null:
			_farm_layer = scene.find_child("FarmLand", true, false) as TileMapLayer
	return _farm_layer

func _ground_dirt_layer() -> TileMapLayer:
	if _ground_layer == null or not is_instance_valid(_ground_layer):
		var scene := get_tree().current_scene
		if scene != null:
			_ground_layer = scene.find_child("Ground", true, false) as TileMapLayer
	return _ground_layer

func _crops() -> Node:
	if _crops_node == null or not is_instance_valid(_crops_node):
		var scene := get_tree().current_scene
		if scene != null:
			_crops_node = scene.find_child("Crops", true, false)
	return _crops_node

## ToolHitComponent (cây/đá) đúng tool đang chọn, NẰM Ô TRƯỚC MẶT.
## DÙNG CHUNG cho cả highlight LẪN việc đánh thật của rìu/cúp (chop_state/mine_state
## gọi hàm này rồi apply_hit) → highlight và chặt luôn khớp tuyệt đối.
func tool_component_in_front() -> ToolHitComponent:
	var grass := BuildingManager.get_grass_layer()
	if grass == null or Global.player == null:
		return null
	var world: Vector2 = grass.to_global(grass.map_to_local(_player_front_cell()))
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, world)
	params.collision_mask = TOOL_HIT_LAYER
	params.collide_with_areas = true
	params.collide_with_bodies = false
	for hit in _space().intersect_shape(params, 8):
		var a = hit.collider
		if a is ToolHitComponent and a.tool == ToolManager.selected_tool:
			return a
	return null

func _tool_target_in_front() -> Node2D:
	var comp := tool_component_in_front()
	return comp.get_parent() as Node2D if comp != null else null

## Ô TRƯỚC MẶT có cây trồng không (khớp với điều kiện trồng/cày của ô đó).
func _crop_in_front_cell() -> bool:
	return _crop_in_area(_player_front_cell(), 0)

## Có cây trồng nào trong vùng (center ± radius ô) không (radius 0 = đúng 1 ô).
func _crop_in_area(center: Vector2i, radius: int) -> bool:
	var crops := _crops()
	if crops == null:
		return false
	var layer := BuildingManager.get_grass_layer()
	for c in crops.get_children():
		if c is Node2D:
			var cc := layer.local_to_map(c.global_position / c.global_scale)
			if absi(cc.x - center.x) <= radius and absi(cc.y - center.y) <= radius:
				return true
	return false

## Danh sách cây trồng trong vùng (center ± radius ô) — để viền khi tưới.
func _crops_in_area(center: Vector2i, radius: int) -> Array:
	var out: Array = []
	var crops := _crops()
	if crops == null:
		return out
	var layer := BuildingManager.get_grass_layer()
	for c in crops.get_children():
		if c is Node2D:
			var cc := layer.local_to_map(c.global_position / c.global_scale)
			if absi(cc.x - center.x) <= radius and absi(cc.y - center.y) <= radius:
				out.append(c)
	return out

func _nearest_animal() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for hit in _circle_query(ANIMAL_LAYER, false):
		var col = hit.collider
		if col is CharacterBody2D and col.get_parent() is PlacedBuilding:
			var d := Global.player.global_position.distance_to(col.global_position)
			if d < best_d:
				best_d = d
				best = col
	return best

func _nearest_crop() -> Node2D:
	var crops := _crops()
	if crops == null:
		return null
	var best: Node2D = null
	var best_d := INTERACT_RADIUS
	for c in crops.get_children():
		if c is Node2D:
			var d := Global.player.global_position.distance_to(c.global_position)
			if d < best_d:
				best_d = d
				best = c
	return best

func _pen_target() -> Node2D:
	var layer := BuildingManager.get_grass_layer()
	var pcell: Vector2i = layer.local_to_map(Global.player.global_position / Global.player.global_scale)
	# Đang ĐỨNG TRONG chuồng → KHÔNG cho phá (tránh nhầm thao tác khi cất gà).
	# Muốn phá chuồng phải đứng ngoài, quay mặt vào nó.
	if BuildingManager.building_at_cell(pcell) != null:
		return null
	return BuildingManager.building_at_cell(_player_front_cell()) as Node2D

## Đối tượng sẽ phá (ưu tiên: vật nuôi > cây trồng > chuồng).
func _resolve_demolish_target() -> Node2D:
	var a := _nearest_animal()
	if a != null:
		return a
	var c := _nearest_crop()
	if c != null:
		return c
	return _pen_target()

## Tool/seed/animal đang chọn có việc ở gần/trước mặt? → nhường, không phá.
func _selected_has_target() -> bool:
	var item: ItemDef = ItemRegistry.get_item(ToolManager.selected_item_id)
	if item != null and item.category == ItemDef.Category.ANIMAL:
		return true
	match ToolManager.selected_tool:
		DataTypes.Tools.Axe, DataTypes.Tools.Pickaxe:
			return _tool_target_in_front() != null
		DataTypes.Tools.WateringCan:
			# Tưới 3x3 quanh ô trước mặt → có cây trong vùng đó thì coi là có việc.
			return _crop_in_area(_player_front_cell(), 1)
		DataTypes.Tools.Hoe:
			# Cuốc tác động lên ô ĐẤT (Ground) CHƯA cày — không phải cỏ, không phải
			# đất đã cày sẵn; bỏ qua nếu Ô TRƯỚC MẶT đã có cây.
			var fc := _player_front_cell()
			var ground := _ground_dirt_layer()
			var farm := _farmland_layer()
			var on_dirt := ground != null and ground.get_cell_source_id(fc) != -1
			var already_farm := farm != null and farm.get_cell_source_id(fc) != -1
			return on_dirt and not already_farm and not _crop_in_front_cell()
		DataTypes.Tools.Seed:
			# Trồng vào Ô TRƯỚC MẶT nếu là đất cày & ô đó chưa có cây (khớp add_crop).
			var farm := _farmland_layer()
			var on_farm := farm != null and farm.get_cell_source_id(_player_front_cell()) != -1
			return on_farm and not _crop_in_front_cell()
	return false

# ---------------------------------------------------------------- Demolish

func _demolish(target: Node2D) -> void:
	if target is PlacedBuilding:
		_demolish_pen(target)
	elif target is CharacterBody2D and target.get_parent() is PlacedBuilding:
		_demolish_animal(target)
	else:
		target.queue_free()  # cây trồng

func _demolish_animal(animal: Node2D) -> void:
	_return_animal_item(animal)
	var pen := animal.get_parent()
	if pen is PlacedBuilding:
		pen.animal_count = maxi(0, pen.animal_count - 1)
	animal.queue_free()

func _demolish_pen(pen: Node2D) -> void:
	if pen is PlacedBuilding:
		for animal in pen.get_animals():
			_return_animal_item(animal)
	BuildingManager.remove_building(pen.get_instance_id())
	pen.queue_free()

func _return_animal_item(animal: Node) -> void:
	if animal.has_meta("animal_item"):
		InventoryManager.add_collectable(String(animal.get_meta("animal_item")))
