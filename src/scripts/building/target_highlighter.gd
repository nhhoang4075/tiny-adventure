class_name TargetHighlighter
extends Node2D

## Báo trước thứ tool/F sẽ tác động. Tất cả MÀU TRẮNG, mờ nhẹ, nhấp nháy theo nhịp.
##
## THIẾT KẾ CHUNG (dùng cho mọi object tương tác được: cây, đá, crop, animal, chuồng,
## và sau này feed_station, chest...):
##  - show_object()/show_objects()/show_pen(): nạp danh sách target.
##  - Mỗi target được "phủ trắng" qua hàm _set_highlight() tổng quát:
##      • Nếu target có method set_highlight(on, amount) → để nó tự lo (vd chuồng: phủ
##        lên TileMapLayer hàng rào). Dùng cho object nhiều phần / không phải sprite.
##      • Ngược lại → tự phủ lên mọi Sprite2D/AnimatedSprite2D (chính nó + con trực tiếp),
##        TỰ GẮN shader object_fx nếu chưa có → object mới chỉ cần là target, KHÔNG cần
##        cấu hình gì thêm.
##  - Đang tương tác (material đang rung, vd đang chặt) → KHÔNG phủ trắng.
##  - show_fill(): phủ 1 lớp trắng lên ô tile (cuốc/hạt giống) — vẽ bằng _draw.

const HIGHLIGHT_COLOR := Color.WHITE
const OBJECT_FX_SHADER := preload("res://scenes/objects/object_fx.gdshader")

# --- ô tile (phủ trắng) ---
var _rect: Rect2
var _rect_active: bool = false
var _fill_alpha: float = 0.3

# --- phủ trắng object: instance_id -> target Node (đang bật) ---
var _targets: Array[Node2D] = []
var _highlighted: Dictionary = {}

var _t: float = 0.0

# ---------------------------------------------------------------- API

func clear() -> void:
	_rect_active = false
	_targets.clear()

func show_fill(local_rect: Rect2) -> void:
	_rect = local_rect
	_rect_active = true

func show_object(target: Node2D) -> void:
	_targets.clear()
	if target != null:
		_targets.append(target)

func show_objects(targets: Array) -> void:
	_targets.clear()
	for t in targets:
		if t is Node2D:
			_targets.append(t)

## Chuồng cũng chỉ là 1 target (PlacedBuilding tự lo qua set_highlight()).
func show_pen(pen: Node2D) -> void:
	if pen != null:
		_targets.append(pen)

# ---------------------------------------------------------------- Cập nhật mỗi frame

func _process(delta: float) -> void:
	_t += delta
	var wave: float = 0.5 + 0.5 * sin(_t * 3.0)
	_fill_alpha = 0.16 + 0.14 * wave
	_update_object_highlight(0.15 + 0.15 * wave)
	queue_redraw()

# --- phủ trắng object (diff theo instance_id) ---

func _update_object_highlight(amount: float) -> void:
	var want: Dictionary = {}
	for t in _targets:
		if is_instance_valid(t):
			want[t.get_instance_id()] = t
	# Tắt phủ ở những object không còn target.
	for id in _highlighted.keys():
		if not want.has(id):
			var node = _highlighted[id]
			if is_instance_valid(node):
				_set_highlight(node, 0.0)
			_highlighted.erase(id)
	# Bật/cập nhật phủ cho object đang target.
	for id in want:
		_set_highlight(want[id], amount)
		_highlighted[id] = want[id]

## Phủ trắng tổng quát cho 1 object. amount 0 = tắt.
func _set_highlight(target: Node2D, amount: float) -> void:
	# Object tự lo (vd chuồng: phủ lên hàng rào TileMapLayer).
	if target.has_method("set_highlight"):
		target.set_highlight(amount > 0.001, amount)
		return
	# Mặc định: phủ lên mọi sprite của object.
	for vis in _collect_visuals(target):
		var mat := _ensure_fx_material(vis)
		if mat == null:
			continue
		# Đang tương tác (đang rung) → không phủ trắng.
		var a := amount
		var si = mat.get_shader_parameter("shake_intensity")
		if si != null and float(si) > 0.0:
			a = 0.0
		mat.set_shader_parameter("highlight_color", HIGHLIGHT_COLOR)
		mat.set_shader_parameter("highlight_amount", a)

## Các sprite cần phủ: chính node (nếu là sprite) + con TRỰC TIẾP là sprite.
## (Không đệ quy sâu để tránh phủ nhầm bong bóng/particle con cháu.)
func _collect_visuals(target: Node2D) -> Array:
	var out: Array = []
	if target is Sprite2D or target is AnimatedSprite2D:
		out.append(target)
	for c in target.get_children():
		if c is Sprite2D or c is AnimatedSprite2D:
			out.append(c)
	return out

## Lấy material object_fx của sprite, TỰ GẮN nếu chưa có. Trả null nếu sprite đã có
## shader KHÁC (không đụng vào để tránh xung đột).
func _ensure_fx_material(vis: CanvasItem) -> ShaderMaterial:
	if vis.material is ShaderMaterial:
		var sm: ShaderMaterial = vis.material
		if sm.shader == OBJECT_FX_SHADER or (sm.shader != null and sm.shader.resource_path == OBJECT_FX_SHADER.resource_path):
			return sm
		return null
	if vis.material == null:
		var m := ShaderMaterial.new()
		m.shader = OBJECT_FX_SHADER
		vis.material = m
		return m
	return null

# --- ô tile ---

func _draw() -> void:
	if not _rect_active:
		return
	draw_rect(_rect, Color(1, 1, 1, _fill_alpha), true)
