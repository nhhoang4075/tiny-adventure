extends Node2D

## Cây trồng generic — chạy hoàn toàn theo CropDef. Trồng bởi CropHandleComponent.
## Tưới mỗi ngày để lớn; quên tưới thì hôm đó tạm dừng (Stardew-style, không chết).
## Thêm loại cây mới = tạo 1 CropDef .tres + 1 ItemDef hạt giống, KHÔNG sửa file này.

@export var crop_def: CropDef

## Báo "cần tưới": scene giọt nước viền nhấp nháy đặt ở góc trên-phải cây.
const WATER_INDICATOR := preload("res://scenes/ui/water_indicator.tscn")

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var watering_particles: GPUParticles2D = $WateringParticles
@onready var flowering_particles: GPUParticles2D = $FloweringParticles

var _grow_days: int = 0       # số ngày ĐƯỢC TƯỚI đã tích luỹ
var _watered_today: bool = false
var _water_anim: AnimatedSprite2D

func setup(def: CropDef) -> void:
	crop_def = def

func _ready() -> void:
	watering_particles.emitting = false
	flowering_particles.emitting = false
	DayNightCycleManager.morning_tick.connect(_on_morning)
	_apply_def()
	_refresh()

	_water_anim = WATER_INDICATOR.instantiate() as AnimatedSprite2D
	add_child(_water_anim)
	_update_water_indicator()

## Hiện giọt nước khi cây còn cần tưới (chưa tưới hôm nay & chưa chín).
func _update_water_indicator() -> void:
	if _water_anim != null:
		_water_anim.visible = (not _watered_today) and (not _is_ripe())

func _apply_def() -> void:
	if crop_def == null:
		return
	if crop_def.sprite_sheet != null:
		sprite_2d.texture = crop_def.sprite_sheet
	sprite_2d.hframes = crop_def.hframes
	sprite_2d.vframes = crop_def.vframes

func _last_stage() -> int:
	return maxi(crop_def.growth_stages - 1, 0)

func _stage() -> int:
	if crop_def == null or crop_def.days_to_harvest <= 0:
		return 0
	var ratio := float(_grow_days) / float(crop_def.days_to_harvest)
	return clampi(int(round(ratio * _last_stage())), 0, _last_stage())

func _is_ripe() -> bool:
	return crop_def != null and _grow_days >= crop_def.days_to_harvest

func _refresh() -> void:
	if crop_def == null:
		return
	sprite_2d.frame_coords = Vector2i(crop_def.sprite_first_col + _stage(), crop_def.sprite_row)
	flowering_particles.emitting = _is_ripe()

## Tưới cây này (gọi từ tưới-theo-vùng 3x3 của CropHandleComponent).
func water() -> void:
	if _watered_today or _is_ripe():
		return
	_watered_today = true
	_update_water_indicator()
	watering_particles.emitting = true
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(watering_particles):
		watering_particles.emitting = false

func _on_morning(_day: int) -> void:
	if crop_def == null:
		return
	if not _watered_today:
		return  # Không tưới hôm qua -> sáng nay không lớn (không chết).
	_watered_today = false
	if _is_ripe():
		return
	_grow_days += 1
	_refresh()
	if _is_ripe():
		_harvest()
	_update_water_indicator()  # sang ngày mới lại cần tưới → hiện giọt nước

func _harvest() -> void:
	if crop_def.product_id != StringName(""):
		var amount := randi_range(crop_def.yield_min, crop_def.yield_max)
		# Rơi ngay tại cây (resolve_landing=false, scatter nhỏ) — chỉ có hiệu ứng nảy.
		Drop.spawn(crop_def.product_id, global_position, amount, true, 4.0, false)
	if crop_def.regrow_days > 0:
		# Tái sinh: lùi tiến độ lại, cần regrow_days ngày tưới để chín lần nữa.
		_grow_days = maxi(0, crop_def.days_to_harvest - crop_def.regrow_days)
		_refresh()
	else:
		queue_free()
