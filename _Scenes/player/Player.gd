extends StaticBody2D
class_name Player

@export var health : Health

var vision_range = Vector2i(10, 8)

signal move_player
# Called when the node enters the scene tree for the first time.
func _ready():
	health.set_max_health(10)
	health.set_health(10)
	pass # Replace with function body.



func _input(event:InputEvent):
	if event.is_action_pressed("Up"):
		get_viewport().set_input_as_handled()
		move(Vector2i.UP)
		return
	if event.is_action_pressed("Down"):
		get_viewport().set_input_as_handled()
		move(Vector2i.DOWN)
		return
	if event.is_action_pressed("Left"):
		get_viewport().set_input_as_handled()
		move(Vector2i.LEFT)
		return
	if event.is_action_pressed("Right"):
		get_viewport().set_input_as_handled()
		move(Vector2i.RIGHT)
		return
	if event.is_action_pressed("SpaceBar"):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Action"):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Escape"):
		get_viewport().set_input_as_handled()
		return

func move(direction : Vector2i):
	move_player.emit(direction)

func take_damage(damage: int):
	health.reduce_health(damage)


func _on_health_out_of_health():
	print("Player died!")
	pass # Replace with function body.
