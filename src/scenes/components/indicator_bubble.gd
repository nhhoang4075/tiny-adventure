class_name IndicatorBubble
extends Node2D

## Bong bóng báo hiệu nổi trên đầu đối tượng, chứa 1 icon bên trong (giọt nước,
## đồ ăn...). Icon có thể tĩnh hoặc động (sprite sheet ngang). Cả bong bóng nhún
## nhẹ lên xuống cho sinh động.
## Dùng: tạo node, set position + scale, add_child, rồi gọi set_icon / set_animated_icon.

const BUBBLE_SHEET := preload("res://assets/Cute_Fantasy_UI/UI/UI_Pop_Up.png")
## Bong bóng vuông có đuôi (ô trên-trái của UI_Pop_Up).
const BUBBLE_REGION := Rect2(14, 14, 20, 24)
## Tâm phần thân bong bóng (đặt icon vào đây, phía trên cái đuôi).
const ICON_CENTER := Vector2(0, -3)
const BOB_AMP := 1.5
const BOB_SPEED := 3.0

var _bubble: Sprite2D
var _icon: Sprite2D
var _frames: int = 1
var _frame_timer: Timer
var _t: float = 0.0
var _base_y: float = 0.0

func _ready() -> void:
	_base_y = position.y

	var atlas := AtlasTexture.new()
	atlas.atlas = BUBBLE_SHEET
	atlas.region = BUBBLE_REGION
	_bubble = Sprite2D.new()
	_bubble.texture = atlas
	add_child(_bubble)

	_icon = Sprite2D.new()
	_icon.position = ICON_CENTER
	_bubble.add_child(_icon)

	_frame_timer = Timer.new()
	_frame_timer.timeout.connect(_advance)
	add_child(_frame_timer)

## Icon tĩnh (vd icon đồ ăn).
func set_icon(texture: Texture2D, fit_px: float = 12.0) -> void:
	_apply(texture, 1, 0.0, fit_px)

## Icon động từ sprite sheet ngang (vd giọt nước 4 frame).
func set_animated_icon(texture: Texture2D, frames: int, frame_time: float, fit_px: float = 12.0) -> void:
	_apply(texture, frames, frame_time, fit_px)

func _apply(texture: Texture2D, frames: int, frame_time: float, fit_px: float) -> void:
	if _icon == null:
		return
	_frames = maxi(frames, 1)
	_icon.texture = texture
	_icon.hframes = _frames
	_icon.frame = 0
	# Co icon cho 1 frame vừa khít lòng bong bóng (~fit_px).
	var fw: float = (float(texture.get_width()) / float(_frames)) if texture != null else 16.0
	var s: float = (fit_px / fw) if fw > 0.0 else 1.0
	_icon.scale = Vector2(s, s)
	if _frames > 1 and frame_time > 0.0:
		_frame_timer.wait_time = frame_time
		_frame_timer.start()
	else:
		_frame_timer.stop()

func _advance() -> void:
	if _frames > 1 and visible:
		_icon.frame = (_icon.frame + 1) % _frames

func _process(delta: float) -> void:
	_t += delta
	position.y = _base_y + sin(_t * BOB_SPEED) * BOB_AMP
