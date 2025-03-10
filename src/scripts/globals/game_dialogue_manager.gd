extends Node

signal dialogue_ended

func exit_dialogue() -> void:
	dialogue_ended.emit()
