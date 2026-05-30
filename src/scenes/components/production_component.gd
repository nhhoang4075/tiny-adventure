class_name ProductionComponent
extends Node

## Cho animal sản xuất sản phẩm (trứng/sữa) theo chu kỳ ngày. Thả vào animal scene.
## Giá trị mặc định dùng cho animal đặt sẵn; AnimalPlacer.configure() ghi đè theo breed.

@export var product_id: StringName
@export var interval_days: int = 1
@export var yield_min: int = 1
@export var yield_max: int = 1

var _days: int = 0

func _ready() -> void:
	DayNightCycleManager.day_tick.connect(_on_day_tick)

## Gán cấu hình từ AnimalDef (breed) khi mua/thả.
func configure(def) -> void:
	if def.product_id != StringName(""):
		product_id = def.product_id
	interval_days = def.production_interval_days
	yield_min = def.yield_min
	yield_max = def.yield_max

func _on_day_tick(_day: int) -> void:
	if product_id == StringName(""):
		return
	_days += 1
	if _days < interval_days:
		return
	_days = 0
	var amount := randi_range(yield_min, yield_max)
	var animal := get_parent() as Node2D
	if animal == null:
		return
	# avoid_buildings = false → sản phẩm rơi ngay trong chuồng, không bị đẩy ra ngoài.
	Drop.spawn(product_id, animal.global_position, amount, false)
