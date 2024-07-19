extends Sprite2D
class_name Enemy



var atk : int
var attack_range = 1
var stunned_turns = 0

## used for book keeping, usefull for letting main know what to get rid when queue_free()
## is used without having to use search().
var index : int

@export var health : Health

@onready var state = 1
## states: 0: dead, 1: asleep, 2: active, 3: incapacitated

signal dead


func take_damage(damage : int):
	if !health.reduce_health(damage): state = 0

func _on_health_out_of_health():
	state = 0
	dead.emit(index)
	queue_free()

func set_enemy_type(type_name: String):
	var enemy_type_dict = Data.ENEMIES[type_name]
	region_rect = enemy_type_dict["Atlas_Coord"]
	atk = enemy_type_dict["Atk"]
	health.set_max_health(enemy_type_dict["HP"])
	health.set_health(enemy_type_dict["HP"])

