class_name Player
extends CharacterBody2D

@export var current_tool: DataTypes.Tools = DataTypes.Tools.None
@export var animated_tool_2d: AnimatedSprite2D

var direction: Vector2 = Vector2.DOWN
