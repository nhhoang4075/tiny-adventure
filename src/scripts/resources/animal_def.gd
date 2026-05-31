class_name AnimalDef
extends Resource

## Định nghĩa data-driven cho một loài động vật mua được.

@export var id: StringName
@export var display_name: String = ""
@export var scene: PackedScene
## Phải khớp BuildingDef.animal_type của chuồng: "poultry" / "livestock".
@export var animal_type: StringName
@export var price: int = 50

## Sản phẩm sinh ra (item_id trong ItemRegistry: "egg"/"milk"). Rỗng = không sản xuất.
@export var product_id: StringName
## Số ngày giữa 2 lần sản xuất.
@export var production_interval_days: int = 1
## Sản lượng mỗi lần (ngẫu nhiên trong khoảng) — breed khác nhau cho khác nhau.
@export var yield_min: int = 1
@export var yield_max: int = 1

## Thức ăn tương ứng (item_id). Phải cho ăn đúng loại MỖI NGÀY thì mới ra sản phẩm.
## Rỗng = không cần cho ăn.
@export var feed_item_id: StringName
