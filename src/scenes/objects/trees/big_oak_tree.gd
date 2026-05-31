extends Sprite2D

@onready var tool_hit_component: ToolHitComponent = $HurtComponent
@onready var damage_component: DamageComponent = $DamageComponent

var stump_scene = preload("res://scenes/objects/trees/big_oak_stump.tscn")

func _ready() -> void:
	add_to_group("build_obstacle")  # chặn đặt công trình lên ô có cây
	tool_hit_component.tool_hit.connect(on_tool_hit)
	damage_component.max_damage_reached.connect(on_max_damage_reached)

func on_tool_hit(_tool: DataTypes.Tools, power: int) -> void:
	damage_component.apply_damage(power)
	material.set_shader_parameter("shake_intensity", 0.5)
	await get_tree().create_timer(0.5).timeout
	material.set_shader_parameter("shake_intensity", 0.0)

func on_max_damage_reached() -> void:
	call_deferred("add_stump_scene")
	Drop.spawn(&"log", global_position, 2)
	queue_free()

func add_stump_scene() -> void:
	var stump_instance = stump_scene.instantiate() as Node2D
	stump_instance.global_position = global_position / global_scale
	get_parent().add_child(stump_instance)
