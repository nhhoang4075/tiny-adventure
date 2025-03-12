extends Node

func store_to_chest(item_scene: Resource, chest_position: Vector2, item_drop_height: int) -> void:
	var item_instance = item_scene.instantiate() as Node2D
	item_instance.global_position = Vector2(chest_position.x, chest_position.y - item_drop_height)
	get_tree().get_first_node_in_group("collectable").add_child(item_instance)
	item_instance.z_index = 1
	
	var time_delay = randf_range(0.5, 1.5)
	await get_tree().create_timer(time_delay).timeout
	
	var tween = get_tree().create_tween()
	tween.tween_property(item_instance, "position", chest_position, 0.5)
	tween.tween_property(item_instance, "scale", Vector2(0.5, 0.5), 0.5)
	tween.tween_callback(item_instance.queue_free)
