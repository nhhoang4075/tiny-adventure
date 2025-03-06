extends NodeState

@export var character: NonPlayableCharacter
@export var animated_sprite_2d: AnimatedSprite2D

func _ready() -> void:
	animated_sprite_2d.animation_finished.connect(on_animation_finished)

func on_animation_finished() -> void:
	if animated_sprite_2d.animation == "starting_sleep":
		animated_sprite_2d.play("sleeping")
	elif animated_sprite_2d.animation == "finishing_sleep":
		transition.emit("Idle")

func _on_process(delta: float) -> void:
	animated_sprite_2d.flip_h = character.direction.x > 0

func _on_physics_process(delta: float) -> void:
	pass

func _on_next_transitions() -> void:
	var current_hour: int = DayNightCycleManager.current_hour
	
	if current_hour >= 5 && current_hour <= 20:
		animated_sprite_2d.play("finishing_sleep")

func _on_enter() -> void:
	animated_sprite_2d.play("starting_sleep")

func _on_exit() -> void:
	animated_sprite_2d.stop()
