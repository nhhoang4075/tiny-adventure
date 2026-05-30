extends Node

class ItemData:
	var id: String
	var display_name: String
	var icon: Texture2D
	var is_tool: bool
	var tool: DataTypes.Tools

	func _init(p_id: String, p_name: String, p_icon: Texture2D, p_is_tool: bool = false, p_tool: DataTypes.Tools = DataTypes.Tools.None) -> void:
		id = p_id
		display_name = p_name
		icon = p_icon
		is_tool = p_is_tool
		tool = p_tool

const TOOL_ICONS_PATH := "res://assets/icons/Outline/Tool_Icons_Outline.png"
const FOOD_ICONS_PATH := "res://assets/icons/Outline/Food_Icons_Outline.png"
const RESOURCE_ICONS_PATH := "res://assets/icons/Outline/Resources_Icons_Outline.png"

var items: Dictionary = {}
var ordered_ids: Array[String] = []

func _ready() -> void:
	_register_tools()
	_register_collectables()

func _register_tools() -> void:
	_add("axe", "Axe", TOOL_ICONS_PATH, Rect2(48, 0, 16, 16), true, DataTypes.Tools.Axe)
	_add("pickaxe", "Pickaxe", TOOL_ICONS_PATH, Rect2(32, 0, 16, 16), true, DataTypes.Tools.Pickaxe)
	_add("hoe", "Hoe", TOOL_ICONS_PATH, Rect2(80, 0, 16, 16), true, DataTypes.Tools.Hoe)
	_add("watering_can", "Watering Can", TOOL_ICONS_PATH, Rect2(96, 0, 16, 16), true, DataTypes.Tools.WateringCan)
	_add("seed_wheat", "Wheat Seed", FOOD_ICONS_PATH, Rect2(16, 48, 16, 16), true, DataTypes.Tools.SeedWheat)
	_add("seed_tomato", "Tomato Seed", FOOD_ICONS_PATH, Rect2(16, 64, 16, 16), true, DataTypes.Tools.SeedTomato)

func _register_collectables() -> void:
	_add("log", "Log", RESOURCE_ICONS_PATH, Rect2(0, 64, 16, 16))
	_add("stone", "Stone", RESOURCE_ICONS_PATH, Rect2(0, 0, 16, 16))
	_add("wheat", "Wheat", FOOD_ICONS_PATH, Rect2(0, 48, 16, 16))
	_add("tomato", "Tomato", FOOD_ICONS_PATH, Rect2(0, 64, 16, 16))
	_add("egg", "Egg", FOOD_ICONS_PATH, Rect2(96, 16, 16, 16))
	_add("milk", "Milk", FOOD_ICONS_PATH, Rect2(112, 0, 16, 16))

func _add(id: String, display_name: String, atlas_path: String, region: Rect2, is_tool: bool = false, tool: DataTypes.Tools = DataTypes.Tools.None) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(atlas_path)
	atlas.region = region
	items[id] = ItemData.new(id, display_name, atlas, is_tool, tool)
	ordered_ids.append(id)

func get_item(id: String) -> ItemData:
	return items.get(id)

func has(id: String) -> bool:
	return items.has(id)
