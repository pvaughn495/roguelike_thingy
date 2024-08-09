extends Control
class_name RangedActionUI

const TILE_SIZE = 16.0
const RET_ORIGIN = Vector2(160.0, 90.0)

@export var reticle : Sprite2D
@export var splash_sprites : Node2D

var item : Item
var valid_tile_list : Array[Vector2i]
var effected_tiles : Array[Vector2i]
var interactable = false
var sel_tile = true
var player_tile : Vector2i
var selected_enemy : int

signal spell_cast
signal get_valid_targets
signal main_msg

func _input(event: InputEvent):
	if !interactable: return
	
	if event.is_action_pressed("Up"):
		get_viewport().set_input_as_handled()
		move_reticle(Vector2i.UP)
		return
	if event.is_action_pressed("Down"):
		get_viewport().set_input_as_handled()
		move_reticle(Vector2i.DOWN)
		return
	if event.is_action_pressed("Left"):
		get_viewport().set_input_as_handled()
		move_reticle(Vector2i.LEFT)
		return
	if event.is_action_pressed("Right"):
		get_viewport().set_input_as_handled()
		move_reticle(Vector2i.RIGHT)
		return
	if event.is_action_pressed("Action"):
		get_viewport().set_input_as_handled()
		attempt_to_cast()
		return

func move_reticle(dir: Vector2i):
	if valid_tile_list.size() == 0: return
	if sel_tile:
		var new_tile = get_reticle_tile() + dir
		if !valid_tile_list.has(new_tile): return
		reticle.position += Vector2(dir) * TILE_SIZE
	else:
		selected_enemy = ((dir.x - dir.y) + selected_enemy)%valid_tile_list.size()
		reticle.position = Vector2(valid_tile_list[selected_enemy] - player_tile)*TILE_SIZE + RET_ORIGIN

func get_reticle_tile()->Vector2i:
	return Vector2i(((reticle.position - RET_ORIGIN)/TILE_SIZE).round())

func request_selectable_tile_list():
	get_valid_targets.emit(Data.ITEMS[item.item_class]["Range"], sel_tile)


func prepare_ui(tile: Vector2i, new_item: Item):
	player_tile = tile
	item = new_item
	var nearest = false
	match Data.ITEMS[item.item_class]["Target"]:
		"Tile": sel_tile = true
		"Enemy": sel_tile = false
		"Auto": 
			nearest = true
			sel_tile = false
		_: print("Error, invalid target type, item: ", item)
	get_valid_targets.emit(Data.ITEMS[item.item_class]["Range"], sel_tile, nearest)
	
	match Data.ITEMS[item.item_class]["Area"]:
		"Orthogonal" : 
			splash_sprites.visible = true
			effected_tiles = [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		"Single" : 
			splash_sprites.visible = false
			effected_tiles = [Vector2i.ZERO]

func attempt_to_cast():
	if !sel_tile:
		if valid_tile_list.size() == 0:
			print("No valid spell targets.")
			return
	
	for i in effected_tiles.size():
		effected_tiles[i] += get_reticle_tile() + player_tile
	
	interactable = false
	spell_cast.emit(item, effected_tiles)

func reset():
	valid_tile_list.resize(0)
	effected_tiles.resize(0)
	reticle.visible = true
	reticle.position = RET_ORIGIN
	selected_enemy = 0
	item = null

func set_tiles_and_emit(tiles : Array[Vector2i]):
	valid_tile_list = tiles.duplicate()
	if valid_tile_list.size() == 0:
		reticle.visible = false
	elif !sel_tile:
		selected_enemy = 0
		reticle.position = Vector2(valid_tile_list[selected_enemy] - player_tile)*TILE_SIZE + RET_ORIGIN
		print(valid_tile_list[selected_enemy] - player_tile, reticle.position, reticle.visible)
	interactable = true




