extends Node

## Tiền tệ của người chơi (vàng).

@export var balance: int = 500

signal changed(balance: int)

func can_afford(amount: int) -> bool:
	return balance >= amount

func spend(amount: int) -> bool:
	if balance < amount:
		return false
	balance -= amount
	changed.emit(balance)
	return true

func add(amount: int) -> void:
	balance += amount
	changed.emit(balance)
