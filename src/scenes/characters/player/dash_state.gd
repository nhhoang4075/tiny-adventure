extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D
@export var dash_speed: int = 120

func _ready() -> void:
	animated_sprite_2d.animation_finished.connect(on_animation_finished)

func on_animation_finished() -> void:
	if GameInputEvents.is_moving():
		transition.emit("Walk")
	else:
		transition.emit("Idle")

func _on_process(delta: float) -> void:
	pass

func _on_physics_process(delta: float) -> void:
	var dash_direction: Vector2
	
	if player.move_direction != Vector2.ZERO:
		dash_direction = player.move_direction
	else:
		dash_direction = player.sprite_direction

	player.velocity = dash_direction * dash_speed
	player.move_and_slide()

func _on_next_transitions() -> void:
	pass

func _on_enter() -> void:
	animated_sprite_2d.flip_h = false
	
	if player.sprite_direction == Vector2.UP:
		animated_sprite_2d.play("dashing_back")
	elif player.sprite_direction == Vector2.DOWN:
		animated_sprite_2d.play("dashing_front")
	elif player.sprite_direction == Vector2.LEFT:
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.play("dashing_side")
	elif player.sprite_direction == Vector2.RIGHT:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play("dashing_side")

func _on_exit() -> void:
	animated_sprite_2d.stop()
