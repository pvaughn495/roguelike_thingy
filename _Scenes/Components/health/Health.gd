extends Node
class_name Health

@export var health: int
@export var max_health : int

signal out_of_health
signal health_changed
signal max_health_changed

func set_max_health(new_max_health: int)->void:
	if new_max_health == max_health: return
	max_health = max(0, new_max_health)
	if max_health == 0:
		out_of_health.emit()
	max_health_changed.emit(max_health)

func get_max_health()->int: return max_health

func increase_max_health(val: int)->void:
	set_max_health(get_max_health()+val)

func set_health(new_health : int)->void:
	if new_health == health: return
	health = clamp(new_health, 0, max_health)
	if health == 0:
		out_of_health.emit()
	health_changed.emit(health)

func get_health()-> int: return health

func reduce_health(amount: int)->int: 
	set_health(health - amount)
	return health

func heal(amount: int)->void: set_health(health + amount)
