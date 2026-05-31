class_name FieldActionComponent
extends Node

## Cuốc đất: biến ô "có thể cuốc" thành đất trồng (vẽ terrain lên FarmLand).
## - Giữ "hit" < 1s khi cầm Hoe  -> cuốc (tạo ô đất trồng).
## - Giữ "hit" >= 2s khi cầm Hoe -> san lại (xoá ô đất trồng).
##
## MỞ RỘNG hệ thống đất:
## - tillable_layers: các layer mà ô của chúng được phép cuốc (mặc định chỉ Ground/
##   đất nâu). Thêm Grass vào đây là cuốc được cả cỏ.
## - farm_land_tile_map_layer + terrain_set + terrain: loại đất trồng tạo ra. Muốn
##   có loại đất khác (vd đất đã bón phân) -> thêm FieldActionComponent khác trỏ tới
##   layer/terrain khác, hoặc đổi terrain ở đây.

## Các layer được phép cuốc (ô có tile ở BẤT KỲ layer nào trong đây là cuốc được).
@export var tillable_layers: Array[TileMapLayer] = []
## Layer đất trồng (đích) — nơi vẽ terrain đất đã cày.
@export var farm_land_tile_map_layer: TileMapLayer
@export var terrain_set: int = 0
@export var terrain: int = 3

## Tương thích ngược: assignment cũ dùng field này. Vẫn coi là 1 layer cuốc được.
@export var ground_tile_map_layer: TileMapLayer

var cell_position: Vector2i
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

	if key_press_time >= 2.0 and not is_action_done:
		is_action_done = true
		if ToolManager.selected_tool == DataTypes.Tools.Hoe:
			get_target_cell()
			remove_farm_land_cell()

	if Input.is_action_just_released("hit") and is_key_pressed:
		if key_press_time < 1.0 and not is_action_done:
			is_action_done = true
			if ToolManager.selected_tool == DataTypes.Tools.Hoe:
				get_target_cell()
				add_farm_land_cell()

	if Input.is_action_just_released("hit"):
		is_key_pressed = false

## Ô kề player theo hướng quay mặt (cardinal) — đứng cạnh là cuốc được.
func get_target_cell() -> void:
	var player_position: Vector2 = Global.player.global_position / Global.player.global_scale
	var player_cell: Vector2i = farm_land_tile_map_layer.local_to_map(player_position)
	var facing: Vector2 = Global.player.sprite_direction
	cell_position = player_cell + Vector2i(roundi(facing.x), roundi(facing.y))
	local_cell_position = farm_land_tile_map_layer.map_to_local(cell_position)

func _is_tillable(cell: Vector2i) -> bool:
	if ground_tile_map_layer != null and ground_tile_map_layer.get_cell_source_id(cell) != -1:
		return true
	for layer in tillable_layers:
		if layer != null and layer.get_cell_source_id(cell) != -1:
			return true
	return false

func add_farm_land_cell() -> void:
	if _is_tillable(cell_position):
		farm_land_tile_map_layer.set_cells_terrain_connect([cell_position], terrain_set, terrain, true)

func remove_farm_land_cell() -> void:
	farm_land_tile_map_layer.set_cells_terrain_connect([cell_position], 0, -1, true)
