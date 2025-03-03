class_name FieldCursorComponent
extends Node

@export var ground_tile_map_layer: TileMapLayer
@export var farm_land_tile_map_layer: TileMapLayer
@export var terrain_set: int = 0
@export var terrain: int = 3

@onready var player: Player = get_tree().get_first_node_in_group("player")

var mouse_position: Vector2
var cell_position: Vector2i
var cell_source_id: int
var local_cell_position: Vector2
var distance: float

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("remove"):
		if ToolManager.selected_tool == DataTypes.Tools.Hoe:
			get_cell_under_mouse()
			remove_farm_land_cell()
	elif event.is_action_pressed("hit"):
		if ToolManager.selected_tool == DataTypes.Tools.Hoe:
			get_cell_under_mouse()
			add_farm_land_cell()

func get_cell_under_mouse() -> void:
	mouse_position = ground_tile_map_layer.get_local_mouse_position()
	cell_position = ground_tile_map_layer.local_to_map(mouse_position)
	cell_source_id = ground_tile_map_layer.get_cell_source_id(cell_position)
	local_cell_position = ground_tile_map_layer.map_to_local(cell_position)
	
	var player_global_position = player.global_position / player.global_scale
	distance = player_global_position.distance_to(local_cell_position)

func add_farm_land_cell() -> void:
	if cell_source_id != -1 && distance < 20.0:
		farm_land_tile_map_layer.set_cells_terrain_connect([cell_position], terrain_set, terrain, true)

func remove_farm_land_cell() -> void:
	if cell_source_id != -1 && distance < 20.0:
		farm_land_tile_map_layer.set_cells_terrain_connect([cell_position], 0, -1, true)
