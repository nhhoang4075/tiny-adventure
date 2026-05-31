class_name Player
extends CharacterBody2D

@onready var tool_hitbox: ToolHitbox = $HitComponent
@onready var ray_cast_2d: RayCast2D = $RayCast2D

@export var current_tool: DataTypes.Tools = DataTypes.Tools.None
@export var animated_tool_2d: AnimatedSprite2D

var move_direction: Vector2 = Vector2.DOWN
var sprite_direction: Vector2 = Vector2.DOWN
var can_move: bool = true

func _ready() -> void:
	Global.player = self
	ToolManager.tool_selected.connect(on_tool_selected)

func on_tool_selected(tool: DataTypes.Tools) -> void:
	current_tool = tool
	tool_hitbox.current_tool = tool

func _process(delta: float) -> void:
	if move_direction != Vector2.ZERO:
		ray_cast_2d.target_position = move_direction.normalized() * 16
