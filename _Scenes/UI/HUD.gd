extends Control
class_name HUD

@export var dungeon_depth_label : Label
@export var wep_textrect : TextureRect
@export var level_label : Label
@export var expbar : ProgressBar

@onready var full_heart = preload("res://Art/kenney_micro-roguelike/Tiles/Colored/tile_0102.png")
@onready var half_heart = preload("res://Art/kenney_micro-roguelike/Tiles/Colored/tile_0101.png")
@onready var empty_heart = preload("res://Art/kenney_micro-roguelike/Tiles/Colored/tile_0100.png")

func update_health(new_health : int):
	var num_full = new_health/2
	var num_half = new_health%2
	var hearts = %HealthBox.get_children()
	for i in min(num_full, hearts.size()):
		hearts[i].texture = full_heart
	if num_half:
		hearts[num_full].texture = half_heart
	for i in range(num_full + num_half, hearts.size()):
		hearts[i].texture = empty_heart

func update_max_health(new_max_health : int)->void:
	var new_num_hearts = new_max_health/2 + new_max_health%2
	var hearts = %HealthBox.get_children()
	if new_num_hearts < hearts.size():
		for i in range(hearts.size() - new_num_hearts, hearts.size()):
			hearts[i].queue_free()
	elif new_num_hearts > hearts.size():
		for i in (new_num_hearts - hearts.size()):
			var new_heart = TextureRect.new()
			new_heart.expand_mode = TextureRect.EXPAND_FIT_WIDTH
			new_heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			new_heart.texture = empty_heart
			%HealthBox.add_child(new_heart)

func update_wep_textrect(texture : Texture2D)->void:
	wep_textrect.texture = texture

func update_level_label(new_level : int)->void:
	var new_label_text : String 
	if new_level:new_label_text = str(new_level)
	else: new_label_text = ""
	print(new_label_text)
	level_label.set_text(new_label_text)

func update_exp_bar(experience: int, exp_to_level: int, exp_gained : int = 0)->void:
	if exp_gained: pass
	expbar.set_value(100.0*float(experience)/float(exp_to_level))
