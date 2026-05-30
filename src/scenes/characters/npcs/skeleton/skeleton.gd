extends NonPlayableCharacter

@onready var interactable_component: InteractableComponent = $InteractableComponent
@onready var interactable_label_component: Control = $InteractableLabelComponent

var dialogue_balloon_scene = preload("res://dialogues/dialogue_balloon.tscn")
var in_range: bool = false

func _ready() -> void:
	interactable_label_component.hide()
	interactable_component.interactable_activated.connect(on_interactable_activated)
	interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
	GameDialogueManager.dialogue_ended.connect(on_dialogue_ended)

func on_interactable_activated() -> void:
	interactable_label_component.show()
	in_range = true

func on_interactable_deactivated() -> void:
	interactable_label_component.hide()
	in_range = false

func on_dialogue_ended() -> void:
	Global.player.can_move = true

func _unhandled_input(event: InputEvent) -> void:
	if in_range:
		if event.is_action_pressed("interact"):
			var dialogue_balloon: BaseDialogueBalloon = dialogue_balloon_scene.instantiate()
			get_tree().current_scene.add_child(dialogue_balloon)
			dialogue_balloon.start(load("res://dialogues/conversations/guide.dialogue"), "start")
			Global.player.can_move = false
