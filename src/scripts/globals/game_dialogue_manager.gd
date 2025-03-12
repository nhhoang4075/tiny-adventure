extends Node

signal dialogue_ended
signal feed_animals

func action_exit_dialogue() -> void:
	dialogue_ended.emit()

func action_feed_animals() -> void:
	feed_animals.emit()
