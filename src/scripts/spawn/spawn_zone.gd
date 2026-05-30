@tool
class_name SpawnZone
extends Area2D

## Vùng spawn theo polygon. Đặt node này vào scene, thêm 1 CollisionPolygon2D con
## và vẽ vùng. Gán resource_ids để giới hạn loại tài nguyên chỉ spawn trong vùng này.
##
## Nếu một resource id được liệt kê ở ÍT NHẤT một SpawnZone, nó CHỈ respawn trong các
## zone đó. Resource không thuộc zone nào → respawn ngẫu nhiên toàn đảo.

## Các ResourceDef.id được phép spawn trong vùng này.
@export var resource_ids: Array[StringName] = []

## Giới hạn số tài nguyên cùng tồn tại trong vùng (-1 = không giới hạn).
@export var max_alive: int = -1

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("spawn_zones")

## Kiểm tra một điểm world có nằm trong vùng (bất kỳ CollisionPolygon2D con nào) không.
func contains_point(world_pos: Vector2) -> bool:
	for child in get_children():
		var poly := child as CollisionPolygon2D
		if poly == null:
			continue
		var local := poly.to_local(world_pos)
		if Geometry2D.is_point_in_polygon(local, poly.polygon):
			return true
	return false

func allows(resource_id: StringName) -> bool:
	return resource_ids.has(resource_id)
