extends Control
class_name MainMenu

const SAVE_FILE_NAMES = ["user://savefile1.tres", "user://savefile2.tres", "user://savefile3.tres"]

@export var cont_butt : Button
@export var load_butt : Button
@export var newgame_butt : Button
@export var settings_butt : Button
@export var credits_butt : Button
@export var butt_container : VBoxContainer
@export var load_popup: PopupMenu
@export var new_popup: PopupMenu

var last_save_file : int

signal load_game
signal new_game

func _ready()->void:
	load_butt.pressed.connect(_on_load_button_pressed)
	load_popup.index_pressed.connect(_on_load_popup_pressed)
	newgame_butt.pressed.connect(_on_new_button_pressed)
	new_popup.index_pressed.connect(_on_new_popup_pressed)
	set_up_mainmenu()

func set_up_mainmenu()->void:
	last_save_file = LastSave.load_last()
	cont_butt.set_disabled(last_save_file == 0)
	
	var has_saves = false
	for i in SAVE_FILE_NAMES.size():
		var i_has_save = ResourceLoader.exists(SAVE_FILE_NAMES[i])
		has_saves = has_saves or i_has_save
		load_popup.set_item_disabled(i, !i_has_save)
	
	cont_butt.grab_focus.call_deferred()
	

func _on_load_button_pressed()->void:
	load_popup.set_visible(true)

func _on_new_button_pressed()->void:
	new_popup.set_visible(true)

func _on_load_popup_pressed(item_idx : int)->void:
	if item_idx < SAVE_FILE_NAMES.size():
		load_game.emit(SAVE_FILE_NAMES[item_idx])

func _on_new_popup_pressed(item_idx : int)->void:
	if item_idx < SAVE_FILE_NAMES.size():
		print("New game, save slot selected: ", SAVE_FILE_NAMES[item_idx])
		new_game.emit(SAVE_FILE_NAMES[item_idx])


func _on_visibility_changed()->void:
	if is_visible(): set_up_mainmenu()
