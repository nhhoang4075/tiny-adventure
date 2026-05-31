class_name CropHandleComponent
extends Node

## Trồng / tưới cây. Nhắm vào ô KỀ player theo hướng đang quay mặt
## (đứng cạnh là làm được, không cần canh chính xác pixel).
## - Hạt giống + "hit" < 1s : trồng vào ô trước mặt (nếu đã cày).
## - Watering Can + "hit"    : tưới CẢ VÙNG 3x3 quanh ô trước mặt.
## (Nhổ cây giờ dùng GIỮ F — xem RemoveController.)
## Loại cây lấy từ ItemDef.crop của hạt đang chọn — thêm cây mới không sửa file này.

@export var farm_land_tile_map_layer: TileMapLayer
## Bán kính tưới (số ô mỗi phía). 1 = vùng 3x3.
@export var water_radius: int = 1

const CROP_SCENE := preload("res://scenes/objects/plants/crop.tscn")

var cell_position: Vector2i
var cell_source_id: int
var local_cell_position: Vector2

var is_key_pressed := false
var key_press_time := 0.0
var is_action_done := false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("hit"):
		is_key_pressed = true
		key_press_time = 0.0
		is_action_done = false

	if Input.is_action_pressed("hit"):
		key_press_time += delta

	if Input.is_action_just_released("hit") and is_key_pressed:
		if key_press_time < 1.0 and not is_action_done:
			is_action_done = true
			if ToolManager.selected_tool == DataTypes.Tools.Seed:
				_aim_front_cell()
				add_crop()
			elif ToolManager.selected_tool == DataTypes.Tools.WateringCan:
				_aim_front_cell()
				water_area()

	if Input.is_action_just_released("hit"):
		is_key_pressed = false

## Ô kề player theo hướng quay mặt (cardinal).
func _aim_front_cell() -> void:
	var player_position: Vector2 = Global.player.global_position / Global.player.global_scale
	var player_cell: Vector2i = farm_land_tile_map_layer.local_to_map(player_position)
	var facing: Vector2 = Global.player.sprite_direction
	cell_position = player_cell + Vector2i(roundi(facing.x), roundi(facing.y))
	cell_source_id = farm_land_tile_map_layer.get_cell_source_id(cell_position)
	local_cell_position = farm_land_tile_map_layer.map_to_local(cell_position)

func _selected_crop_def() -> CropDef:
	var item: ItemDef = ItemRegistry.get_item(ToolManager.selected_item_id)
	if item == null:
		return null
	return item.crop as CropDef

func _crop_cell(node: Node2D) -> Vector2i:
	return farm_land_tile_map_layer.local_to_map(node.global_position / node.global_scale)

func add_crop() -> void:
	if cell_source_id == -1:
		return  # chỉ trồng trên ô đã cày (FarmLand)
	var crop_def := _selected_crop_def()
	if crop_def == null:
		return
	var crops := get_parent().find_child("Crops")
	if crops == null:
		return
	for node in crops.get_children():
		if node is Node2D and _crop_cell(node) == cell_position:
			return  # ô này đã có cây

	var crop := CROP_SCENE.instantiate()
	crop.crop_def = crop_def
	crop.global_position = local_cell_position
	crops.add_child(crop)

## Tưới mọi cây trong vùng (2*water_radius+1)^2 quanh ô trước mặt.
func water_area() -> void:
	var crops := get_parent().find_child("Crops")
	if crops == null:
		return
	for node in crops.get_children():
		if not (node is Node2D) or not node.has_method("water"):
			continue
		var cc := _crop_cell(node)
		if absi(cc.x - cell_position.x) <= water_radius and absi(cc.y - cell_position.y) <= water_radius:
			node.water()
