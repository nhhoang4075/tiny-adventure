class_name GlowCycleComponent
extends Node

@export var current_growth_state: DataTypes.GrowthStates = DataTypes.GrowthStates.Germination
@export_range(5, 365) var days_until_harvest: int = 7

signal crop_maturity
signal crop_harvesting

var is_watered: bool
var starting_day: int
var current_day: int

func _ready() -> void:
	DayNightCycleManager.day_tick.connect(on_day_tick)

func on_day_tick(day: int) -> void:
	if is_watered:
		if starting_day == 0:
			starting_day = day
		
		growth_states(starting_day, day)
		harvest_state(starting_day, day)

func growth_states(starting_day: int, current_day: int) -> void:
	if current_growth_state == DataTypes.GrowthStates.Maturity:
		return
	
	var num_states = DataTypes.GrowthStates.size() - 1 # num_states = 5
	
	current_growth_state = (current_day - starting_day) % num_states + 1
	
	var state_name = DataTypes.GrowthStates.keys()[current_growth_state]
	print("Current growth state: ", current_growth_state, " - ", state_name)
	
	if current_growth_state == DataTypes.GrowthStates.Maturity:
		crop_maturity.emit()

func harvest_state(starting_day: int, current_day: int) -> void:
	if current_growth_state == DataTypes.GrowthStates.Harvesting:
		return
	
	if current_day == starting_day + days_until_harvest:
		current_growth_state = DataTypes.GrowthStates.Harvesting
		crop_harvesting.emit()

func get_current_growth_state() -> DataTypes.GrowthStates:
	return current_growth_state
