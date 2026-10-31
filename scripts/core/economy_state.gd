class_name EconomyState
extends RefCounted

const STARTING_CREDITS: int = 1200

var credits: int = STARTING_CREDITS


func reset() -> void:
	credits = STARTING_CREDITS


func set_credits(new_value: int) -> void:
	credits = maxi(new_value, 0)


func add_credits(amount: int) -> void:
	set_credits(credits + amount)


func spend_credits(amount: int) -> bool:
	if amount < 0 or credits < amount:
		return false
	set_credits(credits - amount)
	return true
