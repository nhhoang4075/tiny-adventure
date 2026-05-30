class_name DespawnComponent
extends Node

## Tự xoá node cha sau delay (có fade trước khi biến mất). Thả vào gốc cây...

@export var delay: float = 5.0
@export var fade_time: float = 0.8

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	await get_tree().create_timer(delay).timeout
	var target := get_parent()
	if not is_instance_valid(target):
		return
	if fade_time > 0.0 and target is CanvasItem:
		var t := create_tween()
		t.tween_property(target, "modulate:a", 0.0, fade_time)
		await t.finished
	if is_instance_valid(target):
		target.queue_free()
