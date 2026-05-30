extends PanelContainer

@onready var tool_buttons: Array[Button] = [
	$MarginContainer/HBoxContainer/Tool1,
	$MarginContainer/HBoxContainer/Tool2,
	$MarginContainer/HBoxContainer/Tool3,
	$MarginContainer/HBoxContainer/Tool4,
	$MarginContainer/HBoxContainer/Tool5,
	$MarginContainer/HBoxContainer/Tool6,
]

func _ready() -> void:
	for i in tool_buttons.size():
		tool_buttons[i].pressed.connect(_on_tool_button_pressed.bind(i + 1))
	ToolManager.tool_selected.connect(_on_tool_selected)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("previous"):
		if ToolManager.selected_tool > 0:
			ToolManager.select_tool(ToolManager.selected_tool - 1)
		else:
			ToolManager.select_tool(DataTypes.Tools.size() - 1)
	elif event.is_action_pressed("next"):
		if ToolManager.selected_tool < DataTypes.Tools.size() - 1:
			ToolManager.select_tool(ToolManager.selected_tool + 1)
		else:
			ToolManager.select_tool(DataTypes.Tools.None)
	elif event.is_action_pressed("release_tool"):
		ToolManager.select_tool(DataTypes.Tools.None)
	elif event is InputEventKey and event.pressed and not event.echo:
		var idx: int = event.keycode - KEY_1
		if idx >= 0 and idx < tool_buttons.size():
			ToolManager.select_tool(idx + 1)

func _on_tool_button_pressed(tool: DataTypes.Tools) -> void:
	ToolManager.select_tool(tool)

func _on_tool_selected(tool: DataTypes.Tools) -> void:
	for i in tool_buttons.size():
		tool_buttons[i].set_pressed_no_signal(tool == i + 1)
