extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D

func _on_process(delta: float) -> void:
	pass

func _on_physics_process(delta: float) -> void:
	if player.sprite_direction == Vector2.UP:
		animated_sprite_2d.play("idling_back")
	elif player.sprite_direction == Vector2.DOWN:
		animated_sprite_2d.play("idling_front")
	elif player.sprite_direction == Vector2.LEFT:
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.play("idling_side")
	elif player.sprite_direction == Vector2.RIGHT:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play("idling_side")

func _on_next_transitions() -> void:
	GameInputEvents.movement_input()
	
	if GameInputEvents.is_dash_pressed():
		transition.emit("Dash")
	elif GameInputEvents.is_movement_input():
		transition.emit("Walk")
		
	player.animated_tool_2d.visible = false
		
	if (player.current_tool != DataTypes.Tools.None && GameInputEvents.use_tool()):
		player.animated_tool_2d.visible = true
		
	if player.animated_tool_2d.visible:
		if player.current_tool == DataTypes.Tools.Axe:
			transition.emit("Chop")
		elif player.current_tool == DataTypes.Tools.Pickaxe:
			transition.emit("Mine")
		elif player.current_tool == DataTypes.Tools.Hoe:
			transition.emit("Till")
		elif player.current_tool == DataTypes.Tools.WateringCan:
			transition.emit("Water")

func _on_enter() -> void:
	player.animated_tool_2d.visible = false

func _on_exit() -> void:
	animated_sprite_2d.stop()
