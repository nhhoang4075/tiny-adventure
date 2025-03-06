class_name SaveLevelDataComponent
extends Node

var level_scene_name: String
var game_data_path: String = "user://game_data/"
var file_name_format: String = "game_data_%s.tres"
var file_name: String
var file_path: String
var game_data_resource: SaveGameDataResource

func _ready() -> void:
	add_to_group("save_level_data_component")
	level_scene_name = get_parent().name
	file_name = file_name_format % level_scene_name
	file_path = game_data_path + file_name

func save_nodes_data() -> void:
	var nodes = get_tree().get_nodes_in_group("save_data_component")
	
	game_data_resource = SaveGameDataResource.new()
	
	if nodes != null:
		for node in nodes:
			if node is SaveDataComponent:
				var save_data_resource: NodeDataResource = node._save_data()
				var save_final_resource = save_data_resource.duplicate()
				game_data_resource.save_data_nodes.append(save_final_resource)

func save_game() -> void:
	if !DirAccess.dir_exists_absolute(game_data_path):
		DirAccess.make_dir_absolute(game_data_path)
	
	save_nodes_data()
	var result: int = ResourceSaver.save(game_data_resource, file_path)
	print("Save result: ", result)

func load_game() -> void:
	if !FileAccess.file_exists(file_path):
		return
	
	game_data_resource = ResourceLoader.load(file_path)
	
	if game_data_resource == null:
		return
	
	var root_node: Window = get_tree().root
	
	for resource in game_data_resource.save_data_nodes:
		if resource is Resource:
			if resource is NodeDataResource:
				resource._load_data(root_node)
