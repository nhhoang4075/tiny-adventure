class_name CropDef
extends Resource

## Định nghĩa data-driven cho một loại cây trồng. Thả 1 file .tres vào
## res://resources/crops/ + 1 ItemDef hạt giống trỏ tới nó là thêm được cây mới —
## dùng chung scene crop.tscn, không cần viết code.

@export var id: StringName
@export var display_name: String = ""

@export_group("Sprite")
## Spritesheet cây (vd Crops.png: 7 cột x 14 hàng, mỗi frame 16x32).
@export var sprite_sheet: Texture2D
@export var hframes: int = 7
@export var vframes: int = 14
## Hàng (frame_coords.y) của cây này trên sheet.
@export var sprite_row: int = 0
## Cột đầu của giai đoạn lớn (Crops.png: cột 0 = biển, 1 = túi hạt, 2..6 = các giai đoạn).
@export var sprite_first_col: int = 2
## Số giai đoạn lớn (số cột). Crops.png = 5 (cột 2..6).
@export var growth_stages: int = 5

@export_group("Growth")
## Số NGÀY ĐƯỢC TƯỚI để chín (mỗi ngày chỉ tính nếu hôm đó được tưới).
@export var days_to_harvest: int = 5

@export_group("Harvest")
## Sản phẩm thu hoạch (item_id trong ItemRegistry) + sản lượng ngẫu nhiên.
@export var product_id: StringName
@export var yield_min: int = 1
@export var yield_max: int = 1
## > 0 = cây tái sinh: sau khi thu hoạch không biến mất, cần thêm bấy nhiêu
## ngày tưới để chín lại (vd cà chua). 0 = thu hoạch xong là hết (vd lúa mì).
@export var regrow_days: int = 0
