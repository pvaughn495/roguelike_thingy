extends Control
class_name EscMenu

@export var escpopup : PopupMenu

var selection : int

signal return_to_game
signal save_and_menu
signal save_and_quit


func grab_foc()->void:
	escpopup.set_visible(true)
	selection = 0
	escpopup.grab_focus()

func _on_popup_menu_popup_hide()->void:
	return_to_game.emit()


func _on_popup_menu_index_pressed(index: int)->void:
	if index <= 3: selection = index
	match index:
		0: return_to_game.emit()
		1: save_and_menu.emit()
		2: print("Settings menu... todo")
		3: save_and_quit.emit()
