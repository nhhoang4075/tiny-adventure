extends NodeState

@export var character: NonPlayableCharacter
@export var animated_sprite_2d: AnimatedSprite2D
@export var navigation_agent_2d: NavigationAgent2D
@export var min_speed: float = 5.0
@export var max_speed: float = 10.0
@export var body_avoidance_component: Area2D

var speed: float
var body_avoidance_counter: int = 0
var _stuck_time: float = 0.0
var _last_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	navigation_agent_2d.velocity_computed.connect(on_safe_velocity_computed)
	body_avoidance_component.body_entered.connect(on_body_enter)
	
	call_deferred("character_setup")

func character_setup() -> void:
	await get_tree().physics_frame
	
	set_movement_target()

func set_movement_target() -> void:	
	var target_positon: Vector2 = NavigationServer2D.map_get_random_point(
		navigation_agent_2d.get_navigation_map(),
		navigation_agent_2d.navigation_layers,
		false
	)
	
	navigation_agent_2d.target_position = target_positon
	speed = randf_range(min_speed, max_speed)
	character.current_walk_cycle += 1

func _on_process(delta: float) -> void:
	pass

func _on_physics_process(delta: float) -> void:
	if navigation_agent_2d.is_navigation_finished():
		set_movement_target()
		return

	# Phát hiện kẹt: đang đi mà gần như không nhúc nhích → chọn đích mới để thoát.
	if character.global_position.distance_to(_last_pos) < 0.3:
		_stuck_time += delta
		if _stuck_time > 0.7:
			_stuck_time = 0.0
			set_movement_target()
			return
	else:
		_stuck_time = 0.0
	_last_pos = character.global_position

	var target_positon: Vector2 = navigation_agent_2d.get_next_path_position()
	var target_direction: Vector2 = character.global_position.direction_to(target_positon)
	var velocity: Vector2 = target_direction * speed
	
	character.direction = target_direction
	
	if navigation_agent_2d.avoidance_enabled:
		navigation_agent_2d.velocity = velocity
	else:
		animated_sprite_2d.flip_h = velocity.x > 0
		character.velocity = velocity
		character.move_and_slide()

func on_safe_velocity_computed(safe_velocity: Vector2) -> void:
	animated_sprite_2d.flip_h = safe_velocity.x > 0
	character.velocity = safe_velocity
	character.move_and_slide()

func on_body_enter(body: Node2D) -> void:
	var is_walking: bool = character.velocity != Vector2.ZERO || navigation_agent_2d.velocity != Vector2.ZERO
	
	if body is Player && is_walking:
		stop_moving()
		
		if body_avoidance_counter > 50:
			body_avoidance_counter = 0
			set_movement_target()
		else:
			transition.emit("Idle")

func _on_next_transitions() -> void:
	var current_hour: int = DayNightCycleManager.current_hour
	var is_sleep_time: bool = current_hour > 20 || current_hour < 5
	var finish_walk_cycles: bool = character.current_walk_cycle == character.walk_cycles
	
	if finish_walk_cycles || is_sleep_time:
		stop_moving()
		transition.emit("Idle")
	
	body_avoidance_counter += 1

func stop_moving() -> void:
	character.velocity = Vector2.ZERO
	navigation_agent_2d.velocity = Vector2.ZERO

func _on_enter() -> void:
	animated_sprite_2d.play("walking")
	character.walk_cycles = randi_range(character.min_walk_cycle, character.max_walk_cycle)
	character.current_walk_cycle = 0

func _on_exit() -> void:
	animated_sprite_2d.stop()
