extends Sprite2D
class_name Enemy


@export var stats : CharacterStats
@export var atk : int
@export var attack_range = 1
@export var stunned_turns = 0
@export var vision = 4
@export var enemy_type: String


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
	enemy_type = type_name
	var enemy_type_dict = Data.ENEMIES[type_name]
	region_rect.position = 9.0*Vector2(enemy_type_dict["Atlas_Coord"])
	atk = enemy_type_dict["Atk"]
	vision = enemy_type_dict["Vision"]
	health.set_max_health(enemy_type_dict["HP"])
	health.set_health(enemy_type_dict["HP"])

