extends Sprite2D

@onready var hurt_component: HurtComponent = $HurtComponent
@onready var damage_component: DamageComponent = $DamageComponent
@onready var modulate_component: Area2D = $ModulateComponent

var stump_scene = preload("res://scenes/objects/trees/big_oak_stump.tscn")
var log_scene = preload("res://scenes/objects/resources/log.tscn")

func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damage_reached.connect(on_max_damage_reached)
	modulate_component.body_entered.connect(on_body_entered)
	modulate_component.body_exited.connect(on_body_exited)

func on_hurt(hit_damage: int) -> void:
	damage_component.apply_damage(hit_damage)
	material.set_shader_parameter("shake_intensity", 0.5)
	await get_tree().create_timer(0.5).timeout
	material.set_shader_parameter("shake_intensity", 0.0)
	call_deferred("add_log_scene")

func on_max_damage_reached() -> void:
	call_deferred("add_log_scene")
	call_deferred("add_stump_scene")
	queue_free()

func add_stump_scene() -> void:
	var stump_instance = stump_scene.instantiate() as Node2D
	stump_instance.global_position = global_position
	get_parent().add_child(stump_instance)
	
func add_log_scene() -> void:
	var log_instance = log_scene.instantiate() as Node2D
	log_instance.global_position = global_position
	get_parent().add_child(log_instance)
	log_instance.drop_to_ground(global_position + Vector2(0, randi_range(12, 16)))

func on_body_entered(body: Node2D) -> void:
	if body is Player:
		modulate.a = 0.6

func on_body_exited(body: Node2D) -> void:
	if body is Player:
		modulate.a = 1
