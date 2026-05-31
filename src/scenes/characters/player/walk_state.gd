extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D
@export var speed: int = 100
@export var acceleration: int = 20

func _on_process(delta: float) -> void:
	pass

func _on_physics_process(delta: float) -> void:
	player.move_direction = GameInputEvents.get_movement_input()
	player.velocity = lerp(player.velocity, player.move_direction * speed, acceleration * delta)
	player.move_and_slide()
	
	if GameInputEvents.is_moving():
		player.sprite_direction = GameInputEvents.sprite_direction()
	
	if player.sprite_direction == Vector2.UP:
		animated_sprite_2d.play("walking_back")
	elif player.sprite_direction == Vector2.DOWN:
		animated_sprite_2d.play("walking_front")
	elif player.sprite_direction == Vector2.LEFT:
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.play("walking_side")
	elif player.sprite_direction == Vector2.RIGHT:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play("walking_side")

func _on_next_transitions() -> void:
	if GameInputEvents.is_dash_pressed():
		transition.emit("Dash")
	elif !GameInputEvents.is_moving():
		transition.emit("Idle")
		
	player.animated_tool_2d.visible = false

	# Data-driven: tool tự khai báo state animation trong ItemDef.action_state.
	# Thêm tool mới = đặt action_state trong .tres + tạo state cùng tên (không sửa đây).
	if GameInputEvents.use_tool():
		var action_state := ToolManager.current_action_state()
		if action_state != StringName(""):
			player.animated_tool_2d.visible = true
			transition.emit(action_state)

func _on_enter() -> void:
	pass

func _on_exit() -> void:
	animated_sprite_2d.stop()
