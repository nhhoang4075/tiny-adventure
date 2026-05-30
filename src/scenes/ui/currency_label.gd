extends Label

func _ready() -> void:
	CurrencyManager.changed.connect(_on_changed)
	_on_changed(CurrencyManager.balance)

func _on_changed(balance: int) -> void:
	text = "Gold: %d" % balance
