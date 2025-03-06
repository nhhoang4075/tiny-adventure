class_name CropsCursorComponent
extends Node

@export var farm_land_tile_map_layer: TileMapLayer

@onready var player: Player = get_tree().get_first_node_in_group("player")

var wheat_plant_scence = preload("res://scences/objects/plants/wheat.tscn")
var tomato_plant_scence = preload("res://scences/objects/plants/tomato.tscn")

var mouse_position: Vector2
var cell_position: Vector2i
var cell_source_id: int
var local_cell_position: Vector2
var distance: float

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("remove"):
		if ToolManager.selected_tool == DataTypes.Tools.Hoe:
			get_cell_under_mouse()
			remove_crop()
	elif event.is_action_pressed("hit"):
		if ToolManager.selected_tool == DataTypes.Tools.SeedWheat || ToolManager.selected_tool == DataTypes.Tools.SeedTomato:
			get_cell_under_mouse()
			add_crop()

func get_cell_under_mouse() -> void:
	mouse_position = farm_land_tile_map_layer.get_local_mouse_position()
	cell_position = farm_land_tile_map_layer.local_to_map(mouse_position)
	cell_source_id = farm_land_tile_map_layer.get_cell_source_id(cell_position)
	local_cell_position = farm_land_tile_map_layer.map_to_local(cell_position)
	
	var player_global_position = player.global_position / player.global_scale
	distance = player_global_position.distance_to(local_cell_position)

func add_crop() -> void:
	if distance < 20.0:
		if ToolManager.selected_tool == DataTypes.Tools.SeedWheat:
			var wheat_instance = wheat_plant_scence.instantiate() as Node2D
			wheat_instance.global_position = local_cell_position
			get_parent().find_child("Crops").add_child(wheat_instance)
		elif ToolManager.selected_tool == DataTypes.Tools.SeedTomato:
			var tomato_instance = tomato_plant_scence.instantiate() as Node2D
			tomato_instance.global_position = local_cell_position
			get_parent().find_child("Crops").add_child(tomato_instance)

func remove_crop() -> void:
	if distance < 20.0:
		var crop_nodes = get_parent().find_child("Crops").get_children()
		
		for node: Node2D in crop_nodes:
			if node.global_position / node.global_scale == local_cell_position:
				node.queue_free()
