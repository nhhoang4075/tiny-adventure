extends Node

## Helper rớt đồ: tạo DroppedItem, tìm điểm đáp hợp lệ (đất, không nước/chuồng),
## rồi chạy hiệu ứng pop+bounce. Cây/đá/animal đều gọi Drop.spawn(...).

const DROPPED_ITEM := preload("res://scenes/objects/dropped_item.tscn")
const SCATTER_MIN := 6.0
const SCATTER_MAX := 16.0
const SPIRAL_MAX_RING := 4

## item_id: id trong ItemRegistry. source_global: vị trí world của nguồn rớt.
## avoid_buildings: true (cây/đá) tránh rơi vào chuồng; false (sản phẩm animal) cho rơi trong chuồng.
func spawn(item_id: StringName, source_global: Vector2, count: int = 1, avoid_buildings: bool = true) -> void:
	# Add vào layer Trees (cùng nơi cây/stump) để y-sort đúng, không bị stump che.
	var layer := BuildingManager.get_object_layer()
	if layer == null:
		return
	var from_local: Vector2 = layer.to_local(source_global)
	for i in count:
		var scatter := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(SCATTER_MIN, SCATTER_MAX)
		var land_local := _resolve_landing(layer, from_local + scatter, from_local, avoid_buildings)
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
