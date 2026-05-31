class_name ToolHitComponent
extends Area2D

## Đối tượng phản ứng khi bị một loại tool tác động (chặt / đập / tưới...).
## Khi ToolHitbox của player chạm vào và tool khớp -> phát tool_hit(tool, power).
## Mỗi đối tượng tự quyết phản ứng: cây/đá mất máu, crop được tưới, v.v.
## (Trước đây tên là HurtComponent / signal "hurt" — đổi vì "hurt" không hợp khi tưới cây.)

@export var tool: DataTypes.Tools = DataTypes.Tools.None

signal tool_hit(tool: DataTypes.Tools, power: int)

## Áp đòn trực tiếp — gọi từ hệ thống dùng tool theo ô trước mặt (cùng nguồn với
## highlight nên luôn khớp). Thay cho cơ chế overlap hitbox.
func apply_hit(power: int) -> void:
	tool_hit.emit(tool, power)

func _on_area_entered(area: Area2D) -> void:
	var hitbox := area as ToolHitbox
	if hitbox == null:
		return

	if tool == hitbox.current_tool:
		tool_hit.emit(tool, hitbox.hit_damage)
