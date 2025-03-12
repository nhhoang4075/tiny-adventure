extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable_component: InteractableComponent = $InteractableComponent
@onready var interactable_label_component: Control = $InteractableLabelComponent
@onready var feed_component: FeedComponent = $FeedComponent
@onready var reward_marker: Marker2D = $RewardMarker

@export var dialogue_start_command: String
@export var item_drop_height: int = 32
@export var reward_output_radius: int = 16
@export var output_reward_scenes: Array[PackedScene] = []

var dialogue_balloon_scene = preload("res://dialogues/dialogue_balloon.tscn")
var wheat_harvest_scene = preload("res://scenes/objects/resources/wheat_harvest.tscn")
var tomato_harvest_scene = preload("res://scenes/objects/resources/tomato_harvest.tscn")

var in_range: bool = false
var is_chest_open: bool = false

func _ready() -> void:
	interactable_label_component.hide()
	interactable_component.interactable_activated.connect(on_interactable_activated)
	interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
	GameDialogueManager.dialogue_ended.connect(on_dialogue_ended)
	GameDialogueManager.feed_animals.connect(on_feed_animals)
	feed_component.food_received.connect(on_food_received)

func on_interactable_activated() -> void:
	interactable_label_component.show()
	in_range = true

func on_interactable_deactivated() -> void:
	interactable_label_component.hide()
	in_range = false
	if is_chest_open:
		animated_sprite_2d.play("chest_close")
		is_chest_open = false

func on_dialogue_ended() -> void:
	Global.player.can_move = true

func on_feed_animals() -> void:
	if in_range:
		call_deferred("trigger_feed_animals", "wheat", wheat_harvest_scene)
		call_deferred("trigger_feed_animals", "tomato", tomato_harvest_scene)

func trigger_feed_animals(item_name: String, item_scene: Resource) -> void:
	var inventory: Dictionary = InventoryManager.inventory
	
	if !inventory.has(item_name):
		return
	
	var inventory_item_count: int = inventory[item_name]
	
	for index in inventory_item_count:
		AnimationManager.store_to_chest(item_scene, global_position, item_drop_height)
		InventoryManager.remove_collectable(item_name)

func on_food_received(area: Area2D) -> void:
	call_deferred("add_reward_scene")

func add_reward_scene() -> void:
	for scene in output_reward_scenes:
		var reward_instance: CollectableBodyComponent = scene.instantiate()
		var reward_positon: Vector2i = get_random_positon_in_circle(reward_marker.global_position, reward_output_radius)
		reward_instance.global_position = global_position
		get_tree().get_first_node_in_group("collectable").add_child(reward_instance)
		reward_instance.drop_to_ground(reward_positon)

func get_random_positon_in_circle(center: Vector2, radius: int) -> Vector2i:
	var angle: float = randf() *  TAU
	var distance_from_center: float = sqrt(randf()) * radius
	var x: int = center.x + distance_from_center * cos(angle)
	var y: int = center.y + distance_from_center * sin(angle)
	
	return Vector2i(x, y)

func _unhandled_input(event: InputEvent) -> void:
	if in_range:
		if event.is_action_pressed("interact"):
			interactable_label_component.hide()
			animated_sprite_2d.play("chest_open")
			is_chest_open = true
			
			var dialogue_balloon: BaseDialogueBalloon = dialogue_balloon_scene.instantiate()
			
			get_tree().current_scene.add_child(dialogue_balloon)
			dialogue_balloon.start(load("res://dialogues/conversations/chest.dialogue"), dialogue_start_command)
			Global.player.can_move = false
