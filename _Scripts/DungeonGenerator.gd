extends RefCounted
class_name DungeonGenerator

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
		"Plate" = Vector2i(2,1),
		"Stair_UP" = Vector2i(5,3),
		"Stair_Down" = Vector2i(4,3),
		"Trap" = Vector2i(2,1),
		"Chest" = Vector2i(9,3)
	}
}

const TILEMAP_LAYERS := {"Base" = 0, "Features" = 1}

var num_rooms : int
var rooms : Array[Rect2i] = []
var connections : Array[Vector2i] = []
var paths : Array[Array] = []
var distance_from_center : Array[Vector2i]
# Called when the node enters the scene tree for the first time.

@warning_ignore("shadowed_variable")
func generate_dungeon(num_rooms: int, min_room_size: int, max_room_size: int):
	## 1. generate room centers with Poisson
	self.num_rooms = num_rooms
	var point_generator = PoissonDiskLoose.new()
	var centers = point_generator.generate_sample(max_room_size, num_rooms, -1)
	
	## 2. grow rooms between the min and max sizes
		## 2.1 Check for overlaps
	
	rooms.resize(num_rooms)
	for i in num_rooms:
		var dx = randi_range(min_room_size/2, max_room_size/2)
		var dy = randi_range(min_room_size/2, max_room_size/2)
		rooms[i] = Rect2i(centers[i], Vector2i.ZERO).grow_individual(dx, dy, dx, dy)
	
	
	## 3. use MST to generate room paths
		## 3.1 come up with a tree structure?
	
	connections = MinimumSpanningTree.prims_alg(centers)
	

func set_dungeon_in_tilemap(tilemap : TileMap):
	paths.resize(0)
	for room in rooms:
		tilemap_outline_rect(room, tilemap)
	for connection in connections:
		paths.append(connect_rooms(rooms[connection[0]], rooms[connection[1]], tilemap))

func get_astar_map(map_rect)->MatrixB:
	
	var map = MatrixB.new(map_rect.size.y, map_rect.size.x, false)
	for room in rooms:
		for x in range(room.position.x + 1, room.end.x -1):
			for y in range(room.position.y + 1, room.end.y -1):
				map.set_at_ij(y - map_rect.position.y, x - map_rect.position.x, true)
	for path in paths:
		for point in path:
			map.set_at_v(point-map_rect.position, true)
	
	return map

func define_room_types():
	## need to choose which rooms are treasure, fights, merchants, etc. 
	## start with a matrix that shows how far each room is from the others.
	var room_connection_matrix = MatrixI.new(num_rooms, num_rooms, num_rooms + 1)
	for i in num_rooms:
		room_connection_matrix.set_at_ij(i, i, 0)
	for connection in connections:
		room_connection_matrix.set_at_ij(connection.x, connection.y, 1)
		room_connection_matrix.set_at_ij(connection.y, connection.x, 1)
	floyd_warshall(num_rooms, room_connection_matrix)
	
	## the room with the smallest maximum row value should be the start or center of the graph
	
	var center_room_index = 0
	var least_max = room_connection_matrix.get_row(center_room_index).max()
	for i in range(1, num_rooms):
		var next_max = room_connection_matrix.get_row(i).max()
		if next_max < least_max:
			center_room_index = i
			least_max = next_max
	
	## create an array of pairs, each pair represents the "room" distance between the rooms and the center
	## room.
	distance_from_center.resize(num_rooms)
	for i in num_rooms:
		distance_from_center[i] = Vector2i(room_connection_matrix.get_from_ij(center_room_index, i),i)
	
	## sort the array by the distance from the center room. Default sort is fine, but you can do custom_sort
	## to just look at the x-val of the Vector2i
	
	distance_from_center.sort()
	
	## now the first element represents the start, the last the end, and treasure rooms should populate
	## from the end
	
	

func connect_rooms(r1:Rect2i,r2:Rect2i, tilemap : TileMap)->Array[Vector2i]:
	var tile_vec = DUN_DICT["Interior"]["Rubble"]
	var tile_layer = TILEMAP_LAYERS["Base"]
	var c1 = r1.get_center()
	var c2 = r2.get_center()
	var diff = (c2 - c1).abs()
	var points : Array[Vector2i] = []
	
	if c1.x == c2.x:
		if c1.y > c2.y: points.append_array(range(c2.y,c1.y+1).map(func(y)->Vector2i: return Vector2i(c1.x,y)))
		else: points.append_array(range(c1.y,c2.y+1).map(func(y)->Vector2i: return Vector2i(c1.x,y)))
	elif c1.y == c2.y:
		if c1.x > c2.x:
			points.append_array(range(c2.x,c1.x+1).map(func(x)->Vector2i: return Vector2i(x,c1.y)))
		else: points.append_array(range(c1.x,c2.x+1).map(func(x)->Vector2i: return Vector2i(x,c1.y)))
		
	elif diff.x > diff.y:
		var mean_x : int
		if c1.x > c2.x:
			mean_x = (r1.position.x + r2.end.x-1)/2
			points.append_array(range(c2.x, mean_x+1).map(func(x)->Vector2i:return Vector2i(x, c2.y)))
			points.append_array(range(mean_x, c1.x+1).map(func(x)->Vector2i:return Vector2i(x, c1.y)))
		else:
			mean_x = (r1.end.x-1 + r2.position.x)/2
			points.append_array(range(c1.x, mean_x+1).map(func(x)->Vector2i:return Vector2i(x, c1.y)))
			points.append_array(range(mean_x, c2.x+1).map(func(x)->Vector2i:return Vector2i(x, c2.y)))
		if c1.y > c2.y: points.append_array(range(c2.y, c1.y).map(func(y)->Vector2i: return Vector2i(mean_x,y)))
		else: points.append_array(range(c1.y, c2.y).map(func(y)->Vector2i: return Vector2i(mean_x,y)))
	else:
		var mean_y : int
		if c1.y > c2.y:
			mean_y = (r1.position.y + r2.end.y-1)/2
			points.append_array(range(c2.y, mean_y+1).map(func(y)->Vector2i:return Vector2i(c2.x, y)))
			points.append_array(range(mean_y, c1.y + 1).map(func(y)->Vector2i:return Vector2i(c1.x, y)))
		else:
			mean_y = (r1.end.y-1 + r2.position.y)/2
			points.append_array(range(c1.y, mean_y+1).map(func(y)->Vector2i:return Vector2i(c1.x, y)))
			points.append_array(range(mean_y, c2.y + 1).map(func(y)->Vector2i:return Vector2i(c2.x, y)))
		if c1.x > c2.x: points.append_array(range(c2.x,c1.x).map(func(x)->Vector2i: return Vector2i(x,mean_y)))
		else: points.append_array(range(c1.x,c2.x).map(func(x)->Vector2i: return Vector2i(x,mean_y)))
	for point in points:
		tilemap.set_cell(tile_layer, point, TILEMAP_SOURCE, tile_vec)
	return points


func tilemap_outline_rect(rect : Rect2i, tilemap : TileMap):
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

func floyd_warshall(num_nodes : int, distance: MatrixI):
	for k in num_nodes:
		for i in num_nodes:
			for j in num_nodes:
				distance.set_at_ij(i,j,min(distance.get_from_ij(i,j), distance.get_from_ij(i,k) 
					+ distance.get_from_ij(k,j)))

func find_dungeon_start_end_nodes(num_nodes : int)-> Vector2i:
	var distance = MatrixI.new(num_nodes, num_nodes, num_nodes + 1)
	
	for i in num_nodes:
		distance.set_at_ij(i, i, 0)
	for connection in connections:
		distance.set_at_ij(connection.x, connection.y, 1)
		distance.set_at_ij(connection.y, connection.x, 1)
	floyd_warshall(num_nodes, distance)
	
	var start_end = Vector2i(-1,-1)
	var smallest_max = num_nodes + 1
	var row : Array[int]
	var row_max_index :int
	row.resize(num_nodes)
	for i in num_nodes:
		row_max_index = 0
		row = distance.get_row(i)
		for j in range(1, num_nodes):
			if row[j] > row[row_max_index]:
				row_max_index = j
		if row[row_max_index] < smallest_max:
			smallest_max = row[row_max_index]
			start_end.x = i
			start_end.y = row_max_index
	return start_end
