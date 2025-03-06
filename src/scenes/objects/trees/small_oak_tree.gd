extends Sprite2D

@onready var hurt_component: HurtComponent = $HurtComponent
@onready var damage_component: DamageComponent = $DamageComponent

var stump_scene = preload("res://scenes/objects/trees/small_oak_stump.tscn")
var log_scene = preload("res://scenes/objects/resources/log.tscn")

func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damage_reached.connect(on_max_damage_reached)

func on_hurt(hit_damage: int) -> void:
	damage_component.apply_damage(hit_damage)
	material.set_shader_parameter("shake_intensity", 0.5)
	await get_tree().create_timer(0.5).timeout
	material.set_shader_parameter("shake_intensity", 0.0)

func on_max_damage_reached() -> void:
	call_deferred("add_stump_scene")
	call_deferred("add_log_scene")
	queue_free()

func add_stump_scene() -> void:
	var stump_instance = stump_scene.instantiate() as Node2D
	stump_instance.global_position = global_position / global_scale
	get_parent().add_child(stump_instance)
	
func add_log_scene() -> void:
	var log_instance = log_scene.instantiate() as Node2D
	log_instance.global_position = global_position / global_scale + Vector2(-10, 20)
	get_parent().add_child(log_instance)
