class_name ToolHitbox
extends Area2D

## Hitbox của tool đang vung (gắn trên player). Va vào ToolHitComponent của đối tượng.
## (Trước đây tên là HitComponent.)

@export var current_tool: DataTypes.Tools = DataTypes.Tools.None
@export var hit_damage: int = 1
