class_name FieldActionComponent
extends Node

@export var ground_tile_map_layer: TileMapLayer
@export var farm_land_tile_map_layer: TileMapLayer
@export var terrain_set: int = 0
@export var terrain: int = 3

@onready var player: Player = get_tree().get_first_node_in_group("player")

var target_size: int = 12
var cell_position: Vector2i
var cell_source_id: int
var local_cell_position: Vector2
var distance: float

var is_key_pressed = false
var key_press_time = 0.0
var is_action_done = false

func _process(delta):
	if Input.is_action_just_pressed("hit"):
		is_key_pressed = true
		key_press_time = 0.0
		is_action_done = false

	if Input.is_action_pressed("hit"):
		key_press_time += delta

	if key_press_time >= 2.0 and !is_action_done:
		is_action_done = true
		if ToolManager.selected_tool == DataTypes.Tools.Hoe:
			get_cell_in_front_of_player()
			remove_farm_land_cell()

	if Input.is_action_just_released("hit") and is_key_pressed:
		if key_press_time < 1.0 and !is_action_done:
			is_action_done = true
			if ToolManager.selected_tool == DataTypes.Tools.Hoe:
				get_cell_in_front_of_player()
				add_farm_land_cell()
	
	if Input.is_action_just_released("hit"):
		is_key_pressed = false

func get_cell_in_front_of_player() -> void:
	var player_position = player.global_position / player.global_scale
	var target_direction = player.direction * target_size
	var target_position = player_position + target_direction
	
	cell_position = ground_tile_map_layer.local_to_map(target_position)
	cell_source_id = ground_tile_map_layer.get_cell_source_id(cell_position)
	local_cell_position = ground_tile_map_layer.map_to_local(cell_position)
	distance = player_position.distance_to(local_cell_position)

func add_farm_land_cell() -> void:
	if cell_source_id != -1 && distance < 20.0:
		farm_land_tile_map_layer.set_cells_terrain_connect([cell_position], terrain_set, terrain, true)

func remove_farm_land_cell() -> void:
	if distance < 20.0:
		farm_land_tile_map_layer.set_cells_terrain_connect([cell_position], 0, -1, true)
