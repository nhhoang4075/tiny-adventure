extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D
@export var hit_component_collision_shape: CollisionShape2D

func _ready() -> void:
	hit_component_collision_shape.disabled = true
	hit_component_collision_shape.position = Vector2.ZERO;

func _on_process(delta: float) -> void:
	pass

func _on_physics_process(delta: float) -> void:
	pass

func _on_next_transitions() -> void:
	if !animated_sprite_2d.is_playing() && !player.animated_tool_2d.is_playing():
		transition.emit("Idle")

func _on_enter() -> void:
	animated_sprite_2d.flip_h = false
	player.animated_tool_2d.flip_h = false
	
	if player.sprite_direction == Vector2.UP:
		animated_sprite_2d.play("chopping_back")
		player.animated_tool_2d.play("axe_back")
		hit_component_collision_shape.position = Vector2(0, -15)
	elif player.sprite_direction == Vector2.DOWN:
		animated_sprite_2d.play("chopping_front")
		player.animated_tool_2d.play("axe_front")
		hit_component_collision_shape.position = Vector2(0, 14)
	elif player.sprite_direction == Vector2.LEFT:
		animated_sprite_2d.flip_h = true
		player.animated_tool_2d.flip_h = true
		animated_sprite_2d.play("chopping_side")
		player.animated_tool_2d.play("axe_side")
		hit_component_collision_shape.position = Vector2(-14, 0)
	elif player.sprite_direction == Vector2.RIGHT:
		animated_sprite_2d.flip_h = false
		player.animated_tool_2d.flip_h = false
		animated_sprite_2d.play("chopping_side")
		player.animated_tool_2d.play("axe_side")
		hit_component_collision_shape.position = Vector2(14, 0)
	else:
		player.animated_tool_2d.play("none")
	
	hit_component_collision_shape.disabled = false

func _on_exit() -> void:
	animated_sprite_2d.stop()
	player.animated_tool_2d.stop()
	
	hit_component_collision_shape.disabled = true
	hit_component_collision_shape.position = Vector2.ZERO;
