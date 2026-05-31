class_name ItemDef
extends Resource

## Định nghĩa data-driven cho MỌI vật phẩm (tool, hạt giống, nông sản, sản phẩm
## chăn nuôi, tài nguyên, thức ăn vật nuôi...). Thả 1 file .tres vào
## res://resources/items/ là thêm được vật phẩm mới — không cần sửa code.
## ItemRegistry quét thư mục này khi khởi động.

## Loại vật phẩm (quyết định hành vi: tool dùng được, seed trồng được, có thể bán...).
enum Category { TOOL, SEED, CROP_PRODUCT, ANIMAL_PRODUCT, RESOURCE, FEED, MISC, ANIMAL }

## Sheet icon nguồn (map sang đường dẫn trong ItemRegistry).
enum IconSheet { TOOL, FOOD, RESOURCE, OTHER }

@export var id: StringName
@export var display_name: String = ""
@export var category: Category = Category.MISC

@export_group("Icon")
@export var icon_sheet: IconSheet = IconSheet.FOOD
## Vùng 16x16 trên sheet.
@export var icon_region: Rect2 = Rect2(0, 0, 16, 16)
## Nếu gán → dùng texture này làm icon thay cho sheet+region (vd icon vật nuôi).
@export var icon_override: Texture2D

@export_group("Economy")
## Giá bán (dùng cho cửa hàng sau này). 0 = không bán được.
@export var sell_price: int = 0

@export_group("Tool / Seed")
## Với TOOL & SEED: tool tương ứng để chọn trên hotbar + animation player.
## Tất cả hạt giống dùng chung DataTypes.Tools.Seed.
@export var tool: DataTypes.Tools = DataTypes.Tools.None
## Với SEED: CropDef sẽ được trồng. (Kiểu Resource để tránh phụ thuộc cứng.)
@export var crop: Resource
## Với ANIMAL: AnimalDef tương ứng (scene/loại/sản phẩm/thức ăn) để đặt vào chuồng.
@export var animal: Resource

## Với TOOL có animation: tên state trong StateMachine của player để vào khi dùng
## (vd "Chop"/"Mine"/"Till"/"Water"). Rỗng = không có animation/hành động state.
## Thêm tool mới chỉ cần đặt field này + tạo state cùng tên trong player — KHÔNG
## phải sửa idle_state/walk_state.
@export var action_state: StringName

## Thứ tự hiển thị trong túi đồ (nhỏ hơn = trước).
@export var sort_order: int = 100

# --- Runtime (ItemRegistry điền sau khi load, không lưu trong .tres) ---
var icon: Texture2D
var is_tool: bool = false
