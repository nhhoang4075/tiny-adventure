extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D
@export var speed: int = 50

func _on_process(delta: float) -> void:
	pass

func _on_physics_process(delta: float) -> void:
	var direction: Vector2 = GameInputEvents.movement_input()
	
	if GameInputEvents.is_movement_input():
		player.direction = direction
	
	if direction == Vector2.UP:
		animated_sprite_2d.play("walking_back")
	elif direction == Vector2.DOWN:
		animated_sprite_2d.play("walking_front")
	elif direction == Vector2.LEFT:
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.play("walking_side")
	elif direction == Vector2.RIGHT:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play("walking_side")
	
	player.velocity = direction * speed
	player.move_and_slide()

func _on_next_transitions() -> void:	
	if !GameInputEvents.is_movement_input():
		transition.emit("Idle")
		
	player.animated_tool_2d.visible = GameInputEvents.use_tool()
		
	if player.animated_tool_2d.visible:
		if player.current_tool == DataTypes.Tools.Axe:
			transition.emit("Chop")
		elif player.current_tool == DataTypes.Tools.Pickaxe:
			transition.emit("Mine")
		elif player.current_tool == DataTypes.Tools.Hoe:
			transition.emit("Till")

func _on_enter() -> void:
	pass

func _on_exit() -> void:
	animated_sprite_2d.stop()
