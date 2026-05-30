extends Node2D

## Item rớt ra với hiệu ứng pop + bounce (fake-height). Node gốc ở vị trí mặt đất
## (nơi nhặt + bóng); chỉ Visual con bay theo parabol. Pickup tắt khi đang bay.

@onready var _visual: Sprite2D = $Visual
@onready var _pickup: CollectableComponent = $CollectableComponent

const PEAK := 16.0
const DUR := 0.42

func setup(item_id: StringName) -> void:
	var data = ItemRegistry.get_item(item_id)
	if data != null:
		_visual.texture = data.icon
	_pickup.collectable_name = item_id
	_pickup.monitoring = false  # chưa cho nhặt khi đang bay

func _draw() -> void:
	# Bóng đổ ở mặt đất (ellipse mờ).
	draw_set_transform(Vector2(0, 3), 0.0, Vector2(1, 0.5))
	draw_circle(Vector2.ZERO, 5.0, Color(0, 0, 0, 0.22))

## from/land: toạ độ LOCAL trong layer chứa item.
func pop_out(from: Vector2, land: Vector2) -> void:
	position = from
	_visual.position = Vector2.ZERO

	# Ngang: trượt từ nguồn tới điểm đáp.
	var th := create_tween()
	th.tween_property(self, "position", land, DUR).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Cao: lên (EASE_OUT) → xuống (EASE_IN) → nảy nhỏ.
	var tv := create_tween()
	tv.tween_property(_visual, "position:y", -PEAK, DUR * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tv.tween_property(_visual, "position:y", 0.0, DUR * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tv.tween_property(_visual, "position:y", -PEAK * 0.3, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tv.tween_property(_visual, "position:y", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tv.tween_callback(func(): _pickup.set_deferred("monitoring", true))
