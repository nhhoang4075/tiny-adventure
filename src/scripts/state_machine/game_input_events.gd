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

static func movement_input() -> Vector2:
	if Input.is_action_pressed("move_up") && Input.is_action_pressed("move_left"):
		direction = DIRECTIONS.UP_LEFT
	elif Input.is_action_pressed("move_up") && Input.is_action_pressed("move_right"):
		direction = DIRECTIONS.UP_RIGHT
	elif Input.is_action_pressed("move_down") && Input.is_action_pressed("move_left"):
		direction = DIRECTIONS.DOWN_LEFT
	elif Input.is_action_pressed("move_down") && Input.is_action_pressed("move_right"):
		direction = DIRECTIONS.DOWN_RIGHT
	elif Input.is_action_pressed("move_up"):
		direction = DIRECTIONS.UP
	elif Input.is_action_pressed("move_down"):
		direction = DIRECTIONS.DOWN
	elif Input.is_action_pressed("move_left"):
		direction = DIRECTIONS.LEFT
	elif Input.is_action_pressed("move_right"):
		direction = DIRECTIONS.RIGHT
	else:
		direction = Vector2.ZERO
		
	return direction

static func is_movement_input() -> bool:
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
	var use_tool_value: bool = Input.is_action_pressed("hit")
	
	return use_tool_value
