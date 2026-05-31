extends Node

## Helper rớt đồ: tạo DroppedItem, tìm điểm đáp hợp lệ (đất, không nước/chuồng),
## rồi chạy hiệu ứng pop+bounce. Cây/đá/animal đều gọi Drop.spawn(...).

const DROPPED_ITEM := preload("res://scenes/objects/dropped_item.tscn")
const SCATTER_MIN := 6.0
const SCATTER_MAX := 16.0
const SPIRAL_MAX_RING := 4

## item_id: id trong ItemRegistry. source_global: vị trí world của nguồn rớt.
## avoid_buildings: true (cây/đá) tránh rơi vào chuồng; false (sản phẩm animal) cho rơi trong chuồng.
## scatter_max: bán kính văng (đơn vị local). < 0 = mặc định (6..16). Truyền nhỏ
##   (vd crop) để đồ rơi ngay tại ô, chỉ có hiệu ứng nảy.
## resolve_landing: true = tìm ô đáp hợp lệ (tránh nước/chuồng, có thể dời xa nếu ô
##   gốc không hợp lệ). false = rơi ngay tại nguồn (dùng khi chắc chắn vị trí đã hợp
##   lệ, vd crop trên đất trồng) → KHÔNG bị dời ra xa.
## parent: nếu truyền (vd CHUỒNG cho sản phẩm animal) → rớt làm con của node đó để
##   y-sort đúng VỚI animal (chuồng đã bật y_sort). Khi đó bỏ qua resolve_landing
##   (rơi ngay tại nguồn + scatter, vì nội thất chuồng vốn hợp lệ).
func spawn(item_id: StringName, source_global: Vector2, count: int = 1, avoid_buildings: bool = true, scatter_max: float = -1.0, resolve_landing: bool = true, parent: Node2D = null) -> void:
	# Mặc định add vào layer Trees (cùng nơi cây/stump) để y-sort đúng, không bị stump che.
	var layer: Node2D = parent if parent != null else BuildingManager.get_object_layer()
	if layer == null:
		return
	if parent != null:
		resolve_landing = false  # parent không phải TileMapLayer → không dò ô lưới được
	var s_max: float = SCATTER_MAX if scatter_max < 0.0 else scatter_max
	var s_min: float = SCATTER_MIN if scatter_max < 0.0 else 0.0
	var from_local: Vector2 = layer.to_local(source_global)
	for i in count:
		var scatter := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(s_min, s_max)
		var land_local: Vector2 = (from_local + scatter) if not resolve_landing else _resolve_landing(layer, from_local + scatter, from_local, avoid_buildings)
		var item := DROPPED_ITEM.instantiate()
		layer.add_child(item)
		item.setup(item_id)
		item.pop_out(from_local, land_local)

func _cell_ok(cell: Vector2i, avoid_buildings: bool) -> bool:
	return BuildingManager.is_land_cell(cell) if avoid_buildings else BuildingManager.is_grass_cell(cell)

const JITTER := 5.0

## Trả về điểm đáp LOCAL hợp lệ. Ưu tiên giữ vị trí scatter liên tục (không snap lưới)
## để đồ nằm tự nhiên; chỉ khi ô đó không hợp lệ mới tìm ô khác (có jitter).
func _resolve_landing(layer: TileMapLayer, candidate_local: Vector2, source_local: Vector2, avoid_buildings: bool) -> Vector2:
	var cand_cell: Vector2i = layer.local_to_map(candidate_local)
	if _cell_ok(cand_cell, avoid_buildings):
		return candidate_local  # giữ nguyên vị trí lệch tâm → không đều, không chồng khít
	var src_cell: Vector2i = layer.local_to_map(source_local)
	for r in range(1, SPIRAL_MAX_RING + 1):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if abs(dx) != r and abs(dy) != r:
					continue  # chỉ viền ngoài của ring
				var c := src_cell + Vector2i(dx, dy)
				if _cell_ok(c, avoid_buildings):
					return layer.map_to_local(c) + Vector2(randf_range(-JITTER, JITTER), randf_range(-JITTER, JITTER))
	return layer.map_to_local(src_cell)  # fallback: rơi tại nguồn
