extends Node

var filename := "user://gamesavetest.tres"

func _input(event: InputEvent)->void:
	if event.is_action_pressed("Left"):
		save_my_game()
	if event.is_action_pressed("Right"):
		load_my_game()
		pass
	if event.is_action_pressed("Action"):
		pass

# Called when the node enters the scene tree for the first time.
func _ready()->void:
	pass


func save_my_game()->void:
	var save = GameSave.new()
	save.player_location = Vector2i(100, 200)
	save.save_game(filename)
	

func load_my_game()->void:
	var save : GameSave
	save = GameSave.load_game(filename)
	print(save.player_location)
