extends Node2D

var tomato_harvest_scene = preload("res://scenes/objects/resources/tomato_harvest.tscn")

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var watering_particles: GPUParticles2D = $WateringParticles
@onready var flowering_particles: GPUParticles2D = $FloweringParticles
@onready var growth_cycle_component: GlowCycleComponent = $GrowthCycleComponent
@onready var tool_hit_component: ToolHitComponent = $HurtComponent

var growth_state: DataTypes.GrowthStates = DataTypes.GrowthStates.Seed

func _ready() -> void:
	watering_particles.emitting = false
	flowering_particles.emitting = false
	
	tool_hit_component.tool_hit.connect(on_tool_hit)
	growth_cycle_component.crop_maturity.connect(on_crop_maturity)
	growth_cycle_component.crop_harvesting.connect(on_crop_harvesting)

func _process(delta: float) -> void:
	growth_state = growth_cycle_component.get_current_growth_state()
	sprite_2d.frame_coords.x = growth_state + 1

func on_tool_hit(_tool: DataTypes.Tools, _power: int) -> void:
	if !growth_cycle_component.is_watered:
		watering_particles.emitting = true
		await get_tree().create_timer(3.0).timeout
		watering_particles.emitting = false
		growth_cycle_component.is_watered = true

func on_crop_maturity() -> void:
	flowering_particles.emitting = true

func on_crop_harvesting() -> void:
	flowering_particles.emitting = false
	call_deferred("add_tomato_harvest_scene")
	queue_free()

func add_tomato_harvest_scene() -> void:
	var tomato_harvest_instance = tomato_harvest_scene.instantiate() as Node2D
	tomato_harvest_instance.global_position = global_position / global_scale
	get_parent().add_child(tomato_harvest_instance)
