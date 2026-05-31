class_name ProductionComponent
extends Node

## Cho animal sản xuất sản phẩm (trứng/sữa) theo chu kỳ ngày. Thả vào animal scene.
## Giá trị mặc định dùng cho animal đặt sẵn; AnimalPlacer.configure() ghi đè theo breed.
## Sản phẩm sinh vào BUỔI SÁNG (morning_tick, khi animal đã thức) chứ không phải lúc
## giao ngày (nửa đêm, animal đang ngủ).

@export var product_id: StringName
@export var interval_days: int = 1
@export var yield_min: int = 1
@export var yield_max: int = 1

var _days: int = 0

# Nếu có HungerComponent cùng cấp → phải được cho ăn mới sản xuất.
@onready var _hunger = get_parent().get_node_or_null("HungerComponent")

func _ready() -> void:
	DayNightCycleManager.morning_tick.connect(_on_morning)

## Gán cấu hình từ AnimalDef (breed) khi mua/thả.
func configure(def) -> void:
	if def.product_id != StringName(""):
		product_id = def.product_id
	interval_days = def.production_interval_days
	yield_min = def.yield_min
	yield_max = def.yield_max

func _on_morning(_day: int) -> void:
	if product_id == StringName(""):
		return
	_days += 1
	if _days < interval_days:
		return
	# Tới kỳ sản xuất: nếu có HungerComponent thì phải đã được cho ăn (hôm trước).
	# Chưa cho ăn → không sản xuất, giữ _days để sáng nào được cho ăn là ra ngay.
	if _hunger != null and not _hunger.consume_fed():
		return
	_days = 0
	var amount := randi_range(yield_min, yield_max)
	var animal := get_parent() as Node2D
	if animal == null:
		return
	# Rớt sản phẩm LÀM CON của chuồng (đã bật y_sort) → y-sort đúng với animal, không
	# còn luôn nằm đè lên animal. Chuồng = node cha của animal.
	var pen := animal.get_parent() as Node2D
	Drop.spawn(product_id, animal.global_position, amount, false, -1.0, false, pen)
