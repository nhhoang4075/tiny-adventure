class_name BuildingDef
extends Resource

## Định nghĩa data-driven cho một công trình đặt được (chuồng, nhà, máy móc...).
## Tạo .tres trong res://resources/buildings/ và chỉnh trong Inspector.

## ID duy nhất, vd "pen_small".
@export var id: StringName
@export var display_name: String = ""

## Kích thước footprint tính bằng ô (hướng gốc, chưa xoay). W x H.
@export var size: Vector2i = Vector2i(4, 3)

## Scene được đặt xuống (xử lý mọi hướng bằng procedural trong PlacedBuilding).
@export var scene: PackedScene

## Tự dựng hàng rào từ terrain (autotile). fence_terrain >= 0 thì bật procedural.
## Terrain index: 4 = Fences-Small, 5 = Fences-Big (theo tile_set). -1 = tắt.
@export var fence_terrain_set: int = 0
@export var fence_terrain: int = -1

## Giá xây.
@export var cost: int = 0

## Sức chứa động vật.
@export var capacity: int = 4

## Loại động vật nuôi được: "poultry" (gia cầm) / "livestock" (gia súc).
@export var animal_type: StringName

## Nav layer (bitmask) cho NavigationRegion2D nội thất. Theo layer_names:
## 1 = Chicken Navigation, 2 = Cow Navigation.
@export var navigation_layer: int = 1

## Cấp cao hơn để nâng cấp (upsize). Để trống nếu là cấp tối đa.
## Kiểu Resource để tránh tự tham chiếu; ép sang BuildingDef khi dùng.
@export var next_tier: Resource

## Trả về danh sách ô footprint quanh origin theo số lần xoay 90° (rot = 0..3).
## Xoay 90° hoán đổi chiều rộng/cao.
func footprint_cells(origin: Vector2i, rot: int) -> Array[Vector2i]:
	var w := size.x
	var h := size.y
	if rot % 2 == 1:
		var tmp := w
		w = h
		h = tmp
	var cells: Array[Vector2i] = []
	for x in w:
		for y in h:
			cells.append(origin + Vector2i(x, y))
	return cells

## Kích thước footprint sau khi xoay (để vẽ ghost).
func rotated_size(rot: int) -> Vector2i:
	if rot % 2 == 1:
		return Vector2i(size.y, size.x)
	return size
