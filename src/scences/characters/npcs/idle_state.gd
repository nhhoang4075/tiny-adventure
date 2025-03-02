extends NodeState

@export var character: NonPlayableCharacter
@export var animated_sprite_2d: AnimatedSprite2D
@export var min_idle_state_interval: float = 2.0
@export var max_idle_state_interval: float = 6.0

@onready var idle_state_timer: Timer = Timer.new()

var idle_state_timeout: bool = false

func _ready() -> void:
	idle_state_timer.timeout.connect(on_idle_state_timeout)
	add_child(idle_state_timer)
	
	character.direction = Vector2(randi_range(-1, 1), 0)

func _on_process(delta: float) -> void:
	animated_sprite_2d.flip_h = character.direction.x > 0

func _on_physics_process(delta: float) -> void:
	pass

func _on_next_transitions() -> void:
	var current_hour: int = DayNightCycleManager.current_hour
	
	if current_hour > 20 || current_hour < 5:
		transition.emit("Sleep")
	elif idle_state_timeout:
		transition.emit("Walk")

func _on_enter() -> void:
	animated_sprite_2d.play("idling")
	idle_state_timeout = false
	idle_state_timer.wait_time = randf_range(min_idle_state_interval, max_idle_state_interval)
	idle_state_timer.start()

func _on_exit() -> void:
	animated_sprite_2d.stop()
	idle_state_timer.stop()

func on_idle_state_timeout() -> void:
	idle_state_timeout = true
