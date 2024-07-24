extends Node2D

const TILEMAP_SOURCE = 0

const DUN_DICT := {
	"Wall" = {
		"Top_Left" = Vector2i(0,9),
		"Top" = Vector2i(1,9),
		"Bottom" = Vector2i(1,9),
		"Top_Right" = Vector2i(3,9),
		"Left" = Vector2i(4,9),
		"Right" = Vector2i(4,9),
		"Bottom_Left" = Vector2i(6,9),
		"Bottom_Right" = Vector2i(9,9)
	},
	"Door" = {
		"Closed" = Vector2i(4,2),
		"Open" = Vector2i(5,2),
		"Restricted" = Vector2i(6,2),
		"Locked" = Vector2i(7,2)
	},
	"Interior" = {
		"Blank" = Vector2i(1,1),
		"Rubble" = Vector2i(4,4),
		"Weeds" = Vector2i(5,4),
		"Plate" = Vector2i(2,1)
	}
}

const TILEMAP_LAYERS := {"Base" = 0, "Features" = 1}

@export var camera : Camera2D
@export var tilemap : TileMap

@onready var point_generator := PoissonDiskLoose.new()


func _ready():
	
	pass


func _unhandled_input(event:InputEvent):
	if event.is_action_pressed("Up"):
		camera.position += 64.0/camera.zoom.x*Vector2.UP
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Down"):
		camera.position += 64.0/camera.zoom.x*Vector2.DOWN
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Left"):
		camera.position += 64.0/camera.zoom.x*Vector2.LEFT
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Right"):
		camera.position += 64.0/camera.zoom.x*Vector2.RIGHT
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Right Carrot"):
		camera.zoom *= 2.0
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Left Carrot"):
		camera.zoom /= 2.0
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("SpaceBar"):
		tilemap.clear()
		make_dungeon(40, 11)
		pass
		get_viewport().set_input_as_handled()


func make_dungeon(num_rooms, min_room_size):
	var dun_gen = DungeonGenerator.new()
	dun_gen.generate_dungeon(num_rooms, min_room_size, 5*min_room_size)
	dun_gen.set_dungeon_in_tilemap(tilemap)


func neighbors_and_weights(source : Vector2i, location: Vector2i, blocking_map : )->Array:
	
	var delta = location - source
	## case: 1: |dx| = |dy|, 2: dx = 0 or dy = 0, 3: |dx| > |dy|, 4: |dx| < |dy|
	if abs(delta.x) > abs(delta.y):
		delta = delta.sign()
		return [[location + delta, 0.5],
			[Vector2i(location.x + delta.x, location.y), 0.5]]
	if abs(delta.x) < abs(delta.y):
		delta = delta.sign()
		return [[location + delta, 0.5],
			Vector2i(location.x, location.y + delta), 0.5]
	if abs(delta.x) == abs(delta.y):
		delta = delta.sign()
		return [[location + delta, 1.0],
			[Vector2i(location.x, location.y + delta.y), 0.5],
			[Vector2i(location.x + delta.x, location.y), 0.5]]
	if delta.x == 0:
		delta = delta.sign()
		return [[location + delta, 0.5],
			[Vector2i(location.x + 1, location.y + delta.y), 0.5],
			[Vector2i(location.x - 1, location.y + delta.y), 0.5]]
	if delta.y == 0:
		delta = delta.sign()
		return [[location + delta, 0.5],
			[Vector2i(location.x + delta.x, location.y + 1), 0.5],
			[Vector2i(location.x + delta.x, location.y - 1), 0.5]]
	return []

func calc_fov(source: Vector2i, range: Vector2i):
	
	
	
	var frontier : Array[Vector2i] = []
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i == 0 and  j == 0: continue
			frontier.append(source + Vector2i(i,j))

