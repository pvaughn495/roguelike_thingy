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
	gen_dungeon(20, 5, 10)
	
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
		gen_dungeon(20, 5, 12)
		pass
		get_viewport().set_input_as_handled()


func gen_dungeon(num_rooms, min_room_size, max_room_size):
	tilemap.clear()
	## 1. generate room centers with Poisson
	
	var centers = point_generator.generate_sample(max_room_size, num_rooms, -1)
	print(centers)
	
	## 2. grow rooms between the min and max sizes
		## 2.1 Check for overlaps
	
	var rooms = centers.map(func(c): 
			var dx = randi_range(min_room_size/2, max_room_size/2-1)
			var dy = randi_range(min_room_size/2, max_room_size/2-1)
			return Rect2i(c, Vector2i.ZERO).grow_individual(dx, dy, dx, dy))
	
	## 3. use MST to generate room paths
		## 3.1 come up with a tree structure?
	
	var connections := MinimumSpanningTree.prims_alg(centers)
	
	## 4. set tilemap tiles
		## a. interiors
		## b. walls
		## c. paths
	for room in rooms:
		tilemap_outline_rect(room)
	for connection in connections:
		connect_rooms(rooms[connection[0]], rooms[connection[1]])
	
	pass

func connect_rooms(r1:Rect2i,r2:Rect2i):
	var tile_vec = DUN_DICT["Interior"]["Rubble"]
	var tile_layer = TILEMAP_LAYERS["Base"]
	var c1 = r1.get_center()
	var c2 = r2.get_center()
	var diff = (c2 - c1).abs()
	var points : Array = []
	
	if c1.x == c2.x:
		if c1.y > c2.y: points = range(c2.y,c1.y+1).map(func(y): return Vector2i(c1.x,y))
		else: points = range(c1.y,c2.y+1).map(func(y): return Vector2i(c1.x,y))
	elif c1.y == c2.y:
		if c1.x > c2.x:
			points = range(c2.x,c1.x+1).map(func(x): return Vector2i(x,c1.y))
		else: points = range(c1.x,c2.x+1).map(func(x): return Vector2i(x,c1.y))
		
	elif diff.x > diff.y:
		var mean_x : int
		if c1.x > c2.x:
			mean_x = (r1.position.x + r2.end.x-1)/2
			points.append_array(range(c2.x, mean_x+1).map(func(x):return Vector2i(x, c2.y)))
			points.append_array(range(mean_x, c1.x+1).map(func(x):return Vector2i(x, c1.y)))
		else:
			mean_x = (r1.end.x-1 + r2.position.x)/2
			points.append_array(range(c1.x, mean_x+1).map(func(x):return Vector2i(x, c1.y)))
			points.append_array(range(mean_x, c2.x+1).map(func(x):return Vector2i(x, c2.y)))
		if c1.y > c2.y: points.append_array(range(c2.y, c1.y).map(func(y): return Vector2i(mean_x,y)))
		else: points.append_array(range(c1.y, c2.y).map(func(y): return Vector2i(mean_x,y)))
	else:
		var mean_y : int
		if c1.y > c2.y:
			mean_y = (r1.position.y + r2.end.y-1)/2
			points.append_array(range(c2.y, mean_y+1).map(func(y):return Vector2i(c2.x, y)))
			points.append_array(range(mean_y, c1.y + 1).map(func(y):return Vector2i(c1.x, y)))
		else:
			mean_y = (r1.end.y-1 + r2.position.y)/2
			points.append_array(range(c1.y, mean_y+1).map(func(y):return Vector2i(c1.x, y)))
			points.append_array(range(mean_y, c2.y + 1).map(func(y):return Vector2i(c2.x, y)))
		if c1.x > c2.x: points.append_array(range(c2.x,c1.x).map(func(x): return Vector2i(x,mean_y)))
		else: points.append_array(range(c1.x,c2.x).map(func(x): return Vector2i(x,mean_y)))
	for point in points:
		tilemap.set_cell(tile_layer, point, TILEMAP_SOURCE, tile_vec)


func tilemap_outline_rect(rect : Rect2i):
	for x in range(rect.position.x+1, rect.end.x-1):
		tilemap.set_cell(0, Vector2i(x, rect.position.y), TILEMAP_SOURCE, DUN_DICT["Wall"]["Top"])
		tilemap.set_cell(0, Vector2i(x, rect.end.y-1), TILEMAP_SOURCE, DUN_DICT["Wall"]["Top"])
	for y in range(rect.position.y+1, rect.end.y-1):
		tilemap.set_cell(0, Vector2i(rect.position.x, y), TILEMAP_SOURCE, DUN_DICT["Wall"]["Left"])
		tilemap.set_cell(0, Vector2i(rect.end.x-1, y), TILEMAP_SOURCE, DUN_DICT["Wall"]["Left"])
	tilemap.set_cell(0, Vector2i(rect.position.x, rect.position.y), TILEMAP_SOURCE, DUN_DICT["Wall"]["Top_Left"])
	tilemap.set_cell(0, Vector2i(rect.position.x, rect.end.y-1), TILEMAP_SOURCE, DUN_DICT["Wall"]["Bottom_Left"])
	tilemap.set_cell(0, Vector2i(rect.end.x-1, rect.position.y), TILEMAP_SOURCE, DUN_DICT["Wall"]["Top_Right"])
	tilemap.set_cell(0, Vector2i(rect.end.x-1, rect.end.y-1), TILEMAP_SOURCE, DUN_DICT["Wall"]["Bottom_Right"])
	var random_int
	for x in range(rect.position.x + 1, rect.end.x -1):
		for y in range(rect.position.y + 1, rect.end.y -1):
			random_int = randi_range(1,50)
			if random_int <= 48:
				tilemap.set_cell(0, Vector2i(x,y), TILEMAP_SOURCE, DUN_DICT["Interior"]["Blank"])
			elif random_int <= 49:
				tilemap.set_cell(0, Vector2i(x,y), TILEMAP_SOURCE, DUN_DICT["Interior"]["Rubble"])
			else:
				tilemap.set_cell(0, Vector2i(x,y), TILEMAP_SOURCE, DUN_DICT["Interior"]["Weeds"])
