class_name GameInputEvents

static var DIRECTIONS = {
	"UP": Vector2.UP,
	"DOWN": Vector2.DOWN,
	"LEFT": Vector2.LEFT,
	"RIGHT": Vector2.RIGHT,
	"UP_LEFT": Vector2(-sqrt(2) / 2, -sqrt(2) / 2),
	"UP_RIGHT": Vector2(sqrt(2) / 2, -sqrt(2) / 2),
	"DOWN_LEFT": Vector2(-sqrt(2) / 2, sqrt(2) / 2),
	"DOWN_RIGHT": Vector2(sqrt(2) / 2, sqrt(2) / 2)
}

static var direction: Vector2

static func get_movement_input() -> Vector2:
	direction = Input.get_vector("left", "right", "up", "down")
	
	return direction

static func movement_input() -> Vector2:
	if Input.is_action_pressed("up") && Input.is_action_pressed("left"):
		direction = DIRECTIONS.UP_LEFT
	elif Input.is_action_pressed("up") && Input.is_action_pressed("right"):
		direction = DIRECTIONS.UP_RIGHT
	elif Input.is_action_pressed("down") && Input.is_action_pressed("left"):
		direction = DIRECTIONS.DOWN_LEFT
	elif Input.is_action_pressed("down") && Input.is_action_pressed("right"):
		direction = DIRECTIONS.DOWN_RIGHT
	elif Input.is_action_pressed("up"):
		direction = DIRECTIONS.UP
	elif Input.is_action_pressed("down"):
		direction = DIRECTIONS.DOWN
	elif Input.is_action_pressed("left"):
		direction = DIRECTIONS.LEFT
	elif Input.is_action_pressed("right"):
		direction = DIRECTIONS.RIGHT
	else:
		direction = Vector2.ZERO
		
	return direction

static func is_moving() -> bool:
	return direction != Vector2.ZERO

static func sprite_direction() -> Vector2:
	if direction in [DIRECTIONS.LEFT, DIRECTIONS.UP_LEFT, DIRECTIONS.DOWN_LEFT]:
		return DIRECTIONS.LEFT
	elif direction in [DIRECTIONS.RIGHT, DIRECTIONS.UP_RIGHT, DIRECTIONS.DOWN_RIGHT]:
		return DIRECTIONS.RIGHT
	else:
		return direction

static func is_dash_pressed() -> bool:
	return Input.is_action_just_pressed("dash")

static func use_tool() -> bool:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _is_mouse_over_ui():
		return Input.is_key_pressed(KEY_F)
	return Input.is_action_pressed("hit")

static func _is_mouse_over_ui() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	return tree.root.gui_get_hovered_control() != null
