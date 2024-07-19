extends Node
class_name Health

var health: int
var max_health : int

signal out_of_health

func set_max_health(new_max_health: int):
	max_health = max(0, new_max_health)
	if max_health == 0:
		out_of_health.emit()

func get_max_health()->int: return max_health

func set_health(new_health : int):
	health = clamp(new_health, 0, max_health)
	if health == 0:
		out_of_health.emit()

func get_health()-> int: return health

func reduce_health(amount: int)->int: 
	set_health(health - amount)
	return health

func heal(amount: int): set_health(health + amount)
