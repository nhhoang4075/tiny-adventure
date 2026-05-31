extends Node

## Tool đang chọn. selected_item_id cho biết CHÍNH XÁC item nào trên hotbar đang
## active — cần thiết vì nhiều hạt giống cùng map về DataTypes.Tools.Seed.

var selected_tool: DataTypes.Tools = DataTypes.Tools.None
var selected_item_id: String = ""

signal tool_selected(tool: DataTypes.Tools)

func select_tool(tool: DataTypes.Tools, item_id: String = "") -> void:
	selected_tool = tool
	selected_item_id = item_id
	tool_selected.emit(tool)

## State animation của item đang chọn (đọc từ ItemDef.action_state). "" = không có.
func current_action_state() -> StringName:
	var item: ItemDef = ItemRegistry.get_item(selected_item_id)
	return item.action_state if item != null else &""
