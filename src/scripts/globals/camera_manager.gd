extends Node

var min_camera_zoom: float = 0.8
var max_camera_zoom: float = 1.6
var zoom_rate_unit: float = 0.2

func _unhandled_input(event: InputEvent) -> void:
	var camera: Camera2D = get_tree().get_first_node_in_group("camera")
	var next_zoom_rate: float
	
	if event.is_action_pressed("scroll_up"):
		next_zoom_rate = minf(camera.zoom.x + zoom_rate_unit, max_camera_zoom)
		camera.zoom = Vector2(next_zoom_rate, next_zoom_rate)
	elif event.is_action_pressed("scroll_down"):
		next_zoom_rate = maxf(camera.zoom.x - zoom_rate_unit, min_camera_zoom)
		camera.zoom = Vector2(next_zoom_rate, next_zoom_rate)
