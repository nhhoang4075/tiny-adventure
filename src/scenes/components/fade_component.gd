class_name FadeComponent
extends Area2D

## Làm mờ object khi player đứng sau (overlap vùng này). Thả vào cây to, nhà...
## Vùng phát hiện = CollisionShape2D con (phủ phần tán/thân che khuất player).
## collision_mask phải bật layer Player (2).

@export var faded_alpha: float = 0.5
@export var fade_time: float = 0.2
## Node cần làm mờ; để trống = node cha.
@export var target_path: NodePath

var _target: CanvasItem
var _overlaps: int = 0

func _ready() -> void:
	if target_path.is_empty():
		_target = get_parent() as CanvasItem
	else:
		_target = get_node(target_path) as CanvasItem
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_overlaps += 1
		_fade_to(faded_alpha)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_overlaps = max(0, _overlaps - 1)
		if _overlaps == 0:
			_fade_to(1.0)

func _fade_to(alpha: float) -> void:
	if _target == null:
		return
	var t := create_tween()
	t.tween_property(_target, "modulate:a", alpha, fade_time)
