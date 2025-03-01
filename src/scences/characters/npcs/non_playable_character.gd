class_name NonPlayableCharacter
extends CharacterBody2D

@export var min_walk_cycle: int = 1
@export var max_walk_cycle: int = 4

var walk_cycles: int
var current_walk_cycle: int
var direction: Vector2
