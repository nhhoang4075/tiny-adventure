class_name CropHandleComponent
extends Node

@export var farm_land_tile_map_layer: TileMapLayer

var wheat_plant_scene = preload("res://scenes/objects/plants/wheat.tscn")
var tomato_plant_scene = preload("res://scenes/objects/plants/tomato.tscn")

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
			remove_crop()
	
	if Input.is_action_just_released("hit") and is_key_pressed:
		if key_press_time < 1.0 and !is_action_done:
			is_action_done = true
			if ToolManager.selected_tool == DataTypes.Tools.SeedWheat || ToolManager.selected_tool == DataTypes.Tools.SeedTomato:
				get_cell_in_front_of_player()
				add_crop()

	if Input.is_action_just_released("hit"):
		is_key_pressed = false

#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("remove"):
		#if ToolManager.selected_tool == DataTypes.Tools.Hoe:
			#get_cell_in_front_of_player()
			#remove_crop()
	#elif event.is_action_pressed("hit"):
		#if ToolManager.selected_tool == DataTypes.Tools.SeedWheat || ToolManager.selected_tool == DataTypes.Tools.SeedTomato:
			#get_cell_in_front_of_player()
			#add_crop()

func get_cell_in_front_of_player() -> void:
	var player_position = Global.player.global_position / Global.player.global_scale
	var target_position = player_position + Global.player.ray_cast_2d.target_position
	
	cell_position = farm_land_tile_map_layer.local_to_map(target_position)
	cell_source_id = farm_land_tile_map_layer.get_cell_source_id(cell_position)
	local_cell_position = farm_land_tile_map_layer.map_to_local(cell_position)
	distance = player_position.distance_to(local_cell_position)

func add_crop() -> void:
	if cell_source_id != -1 && distance < 20.0:
		var crop_nodes = get_parent().find_child("Crops").get_children()
	
		for node: Node2D in crop_nodes:
			if node.global_position / node.global_scale == local_cell_position:
				return # this cell is occupied
		
		if ToolManager.selected_tool == DataTypes.Tools.SeedWheat:
			var wheat_instance = wheat_plant_scene.instantiate() as Node2D
			wheat_instance.global_position = local_cell_position
			get_parent().find_child("Crops").add_child(wheat_instance)
		elif ToolManager.selected_tool == DataTypes.Tools.SeedTomato:
			var tomato_instance = tomato_plant_scene.instantiate() as Node2D
			tomato_instance.global_position = local_cell_position
			get_parent().find_child("Crops").add_child(tomato_instance)

func remove_crop() -> void:
	if distance < 20.0:
		var crop_nodes = get_parent().find_child("Crops").get_children()
		
		for node: Node2D in crop_nodes:
			if node.global_position / node.global_scale == local_cell_position:
				node.queue_free()
