extends PanelContainer

@onready var tool_1: Button = $MarginContainer/HBoxContainer/Tool1
@onready var tool_2: Button = $MarginContainer/HBoxContainer/Tool2
@onready var tool_3: Button = $MarginContainer/HBoxContainer/Tool3
@onready var tool_4: Button = $MarginContainer/HBoxContainer/Tool4
@onready var tool_5: Button = $MarginContainer/HBoxContainer/Tool5

#func _on_tool_1_pressed() -> void:
	#ToolManager.select_tool(DataTypes.Tools.Axe)
#
#func _on_tool_2_pressed() -> void:
	#ToolManager.select_tool(DataTypes.Tools.Pickaxe)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("change_tool"):
		if ToolManager.selected_tool < DataTypes.Tools.size() - 1:
			ToolManager.select_tool(ToolManager.selected_tool + 1)
		else:
			ToolManager.select_tool(DataTypes.Tools.None)
	
	if event.is_action_pressed("release_tool"):
		ToolManager.select_tool(DataTypes.Tools.None)
		
	tool_1.set_pressed_no_signal(false)
	tool_2.set_pressed_no_signal(false)
	tool_3.set_pressed_no_signal(false)
	tool_4.set_pressed_no_signal(false)
	tool_5.set_pressed_no_signal(false)
		
	if ToolManager.selected_tool == 1:
		tool_1.set_pressed_no_signal(true)
	elif ToolManager.selected_tool == 2:
		tool_2.set_pressed_no_signal(true)
	elif ToolManager.selected_tool == 3:
		tool_3.set_pressed_no_signal(true)
	elif ToolManager.selected_tool == 4:
		tool_4.set_pressed_no_signal(true)
