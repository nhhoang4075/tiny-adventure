class_name FeedStation
extends Node2D

## Khu cho ăn của chuồng (khay nước + rơm) — scene tự lo art + collision + vùng cho ăn.
## Đặt làm con của chuồng. Cho ăn: đứng trong "FeedZone" + nhấn interact → cho ăn TẤT
## CẢ con trong chuồng (mỗi con chỉ ăn khi đang chọn đúng thức ăn của nó & còn trong túi).
## Art/collision/vùng-cho-ăn đều chỉnh kéo-thả trong editor (feed_station_*.tscn).

@onready var _feed_zone: Area2D = $FeedZone

var _player_in_zone: bool = false

func _ready() -> void:
	_feed_zone.body_entered.connect(_on_body_entered)
	_feed_zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_zone = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_zone = false

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if not _player_in_zone:
		return
	feed_all()

func feed_all() -> void:
	var pen := get_parent()
	if pen == null:
		return
	for child in pen.get_children():
		var hunger = child.get_node_or_null("HungerComponent")
		if hunger != null and hunger.has_method("feed"):
			hunger.feed()

## Ghost lúc đặt: tắt collision (StaticBody) + vùng cho ăn để không cản / không feed.
func set_ghost(on: bool) -> void:
	_feed_zone.monitoring = not on
	for body in find_children("*", "StaticBody2D"):
		body.collision_layer = 0 if on else 1

## Bao đóng (local) các shape collision — để chuồng khoét vùng này khỏi nav,
## cho animal đi vòng tránh thay vì cấn vào.
func get_blocked_rect() -> Rect2:
	var rect := Rect2()
	var first := true
	for body in find_children("*", "StaticBody2D"):
		for node in body.find_children("*", "CollisionShape2D"):
			var s = node.shape
			if s == null:
				continue
			var sz: Vector2 = s.size if ("size" in s) else Vector2(16, 16)
			var center: Vector2 = body.position + node.position
			var r := Rect2(center - sz * 0.5, sz)
			if first:
				rect = r
				first = false
			else:
				rect = rect.merge(r)
	return rect
