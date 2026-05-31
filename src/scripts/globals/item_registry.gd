extends Node

## Đăng ký vật phẩm data-driven: quét res://resources/items/*.tres (ItemDef) khi
## khởi động. Thêm vật phẩm mới = thả 1 file .tres, KHÔNG cần sửa code.

const ITEMS_DIR := "res://resources/items/"

const SHEET_PATHS := {
	ItemDef.IconSheet.TOOL: "res://assets/icons/Outline/Tool_Icons_Outline.png",
	ItemDef.IconSheet.FOOD: "res://assets/icons/Outline/Food_Icons_Outline.png",
	ItemDef.IconSheet.RESOURCE: "res://assets/icons/Outline/Resources_Icons_Outline.png",
	ItemDef.IconSheet.OTHER: "res://assets/icons/Outline/Other_Icons_Outline.png",
}

var items: Dictionary = {}          # id (String) -> ItemDef
var ordered_ids: Array[String] = []  # theo sort_order
var _sheets: Dictionary = {}         # path -> Texture2D (cache)

func _ready() -> void:
	_load_items()

func _load_items() -> void:
	var defs: Array = []
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_error("ItemRegistry: không mở được " + ITEMS_DIR)
		return
	for file in dir.get_files():
		var fname := file.trim_suffix(".remap")
		if not (fname.ends_with(".tres") or fname.ends_with(".res")):
			continue
		var res = load(ITEMS_DIR + fname)
		if res is ItemDef and res.id != StringName(""):
			defs.append(res)
	defs.sort_custom(func(a, b): return a.sort_order < b.sort_order)
	for def in defs:
		def.icon = _build_icon(def)
		def.is_tool = def.category == ItemDef.Category.TOOL or def.category == ItemDef.Category.SEED
		var key := String(def.id)
		items[key] = def
		ordered_ids.append(key)

func _build_icon(def: ItemDef) -> Texture2D:
	if def.icon_override != null:
		return def.icon_override
	var path: String = SHEET_PATHS.get(def.icon_sheet, "")
	if path == "":
		return null
	if not _sheets.has(path):
		_sheets[path] = load(path)
	var atlas := AtlasTexture.new()
	atlas.atlas = _sheets[path]
	atlas.region = def.icon_region
	return atlas

func get_item(id) -> ItemDef:
	return items.get(String(id))

func has(id) -> bool:
	return items.has(String(id))
