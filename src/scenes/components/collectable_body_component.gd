class_name CollectableBodyComponent
extends RigidBody2D

var ground_position: Vector2
var is_falling: bool = false

func _ready() -> void:
	gravity_scale = 0

func _physics_process(delta: float) -> void:
	if is_falling:
		linear_velocity.y += 5
		if position.y >= ground_position.y:
			linear_velocity = Vector2.ZERO
			is_falling = false
			z_index = 0

func drop_to_ground(target_ground_position: Vector2) -> void:
	var force_direction = Vector2(randf_range(-1, 1), -1).normalized()
	
	linear_velocity = force_direction * randf_range(50, 70)
	ground_position = target_ground_position
	is_falling = true
	z_index = 1
