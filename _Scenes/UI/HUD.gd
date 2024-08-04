extends Control
class_name HUD

@export var dungeon_depth_label : Label
@export var wep_textrect : TextureRect

@onready var full_heart = preload("res://Art/kenney_micro-roguelike/Tiles/Colored/tile_0102.png")
@onready var half_heart = preload("res://Art/kenney_micro-roguelike/Tiles/Colored/tile_0101.png")
@onready var empty_heart = preload("res://Art/kenney_micro-roguelike/Tiles/Colored/tile_0100.png")

func update_health(new_health : int):
	var num_full = new_health/2
	var num_half = new_health%2
	var hearts = %HealthBox.get_children()
	for i in num_full:
		hearts[i].texture = full_heart
	if num_half:
		hearts[num_full].texture = half_heart
	for i in range(num_full + num_half, hearts.size()):
		hearts[i].texture = empty_heart
	pass

func update_max_health(new_max_health : int):
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

func update_wep_textrect(texture : Texture2D):
	wep_textrect.texture = texture
