extends Node2D

const TILE_CENTER_OFFSET = Vector2(-4.0,-4.0)

@export var player : Player
@export var tilemap : TileMap
@export var camera : Camera2D
@export var enemy_scene : PackedScene


var astar_offset : Vector2i
var rooms : Array[Rect2i]

@onready var enemy_list : Array[Enemy] = []
@onready var enemy_tile_location_list : Array[Vector2i] = []
@onready var astar_map := AStarPath.new()

## turn flow:
## 1. player moves
## 2. enemies move
## 3. ???
## 4. profit


var turn_state = 0
var active = false

# Called when the node enters the scene tree for the first time.
func _ready():
	make_new_level()
	turn_state = 1
	active = true

func _physics_process(delta):
	if enemy_list.size() < 10 and active:
		spawn_random_enemy()



func _on_player_move_player(direction: Vector2i):
	match turn_state:
		0: 
			print("Admin turn, please wait.")
			return
		1: pass
			
		2: 
			print("Awaiting enemy turns")
			return
	var new_tile_pos =  tilemap.local_to_map(player.position) + direction
	## if tile has an enemy:
	var enemy_index = enemy_tile_location_list.find(new_tile_pos)
	if enemy_index >= 0:
		enemy_list[enemy_index].take_damage(1)
	elif astar_map.map.get_from_v(new_tile_pos-astar_offset):
		move_entity_to_tile(player, new_tile_pos)
		move_cam_to_player()
	else: 
		print("can't move player to ", new_tile_pos, ", not traversable")
		return
	turn_state = 2
	enemy_turn()


func move_entity_to_tile(entity : Node2D, new_tile_pos: Vector2i):
	entity.position = tilemap.map_to_local(new_tile_pos) #+ TILE_CENTER_OFFSET

func enemy_turn():
	if turn_state == 2:
		turn_state = 1
	else: 
		print("Error: enemy turn called, state: ", turn_state)
		return
	
	var player_tile = tilemap.local_to_map(player.position)
	var enemies = $Enemies.get_children()
	for enemy in enemies:
		enemy_action(enemy, player_tile)

func enemy_action(enemy : Enemy, player_tile):
	match enemy.state:
		0: return ## if dead, do nothing
		1: ## if asleep, check whether to wake up or not
			if Norms.vector2i_l1(tilemap.local_to_map(enemy.position) - player_tile) < 10:
				enemy.state = 2
			return
		2: ## if awake, attack the player if in range, else move
			pass
		3: ## if stunned, count down stunned turns, exit in an asleep state
			if enemy.stunned_turns > 0:
				enemy.stunned_turns -= 1
			else:
				enemy.state = 1
			return
	
	var enemy_tile = tilemap.local_to_map(enemy.position)
	
	## check if the enemy is close enough to the player, if so attack the player
	if Norms.vector2_l1(enemy_tile - player_tile) <= enemy.attack_range:
		enemy_attack(enemy)
		return
	## if not in range, pathfind to the player. 
	var enemy_path = pathfinder(enemy_tile, player_tile)
	if enemy_path.size() > 0:## if path exists:
		if enemy_tile_location_list.has(enemy_path[1]): return ##enemy in the way
		## success, not obstacles, move one step and update
		move_entity_to_tile(enemy, enemy_path[1])
		enemy_tile_location_list[enemy.index] = enemy_path[1]

func enemy_attack(enemy: Enemy):
	print("enemy ", enemy, " attacks player!")

func move_cam_to_player():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(camera, "position", player.position, 0.5)

func make_new_level():
	## clear the old level
	tilemap.clear()
	
	## fire up the dungeon generator
	var dun_gen = DungeonGenerator.new()
	dun_gen.generate_dungeon(12, 6, 9)
	dun_gen.set_dungeon_in_tilemap(tilemap)
	rooms = dun_gen.rooms.duplicate()
	dun_gen.define_room_types()
	move_entity_to_tile(player, dun_gen.rooms[dun_gen.distance_from_center[0].y].get_center())
	camera.position = player.position
	spawn_enemy(dun_gen.rooms[dun_gen.distance_from_center[-1].y].get_center())
	
	
	## set the pathfinding map
	var tilemap_rect = tilemap.get_used_rect()
	astar_map.map = dun_gen.get_astar_map(tilemap_rect)
	astar_offset = tilemap_rect.position


func pathfinder(start : Vector2i, end : Vector2i)->Array[Vector2i]:
	
	var shifted_path = astar_map.a_star_search(start - astar_offset, end - astar_offset, 100)
	
	var path : Array[Vector2i] = []
	for point in shifted_path:
		path.append(point + astar_offset)
	
	return path

func spawn_enemy(tile_location :Vector2i, enemy_type : String = "Rat"):
	var new_enemy = enemy_scene.instantiate()
	new_enemy.position = tilemap.map_to_local(tile_location)
	$Enemies.add_child(new_enemy)
	new_enemy.index = enemy_list.size()
	enemy_list.append(new_enemy)
	enemy_tile_location_list.append(tile_location)
	new_enemy.dead.connect(del_enemy)

func del_enemy(enemy_index : int):
	## book keeping for the list of enemies and their locations
	enemy_list.remove_at(enemy_index)
	enemy_tile_location_list.remove_at(enemy_index)
	## re-index each of the enemies in the list after the deleted entry
	for i in range(enemy_index, enemy_list.size()):
		enemy_list[i].index = i

func spawn_random_enemy():
	var b = true
	while(b):
		var random_room = rooms.pick_random()
		if random_room.has_point(tilemap.local_to_map(player.position)): continue
		var random_room_tile = Vector2i(randi_range(random_room.position.x+1,random_room.end.x -2), 
			randi_range(random_room.position.y+1,random_room.end.y -2))
		if enemy_tile_location_list.has(random_room_tile): continue
		spawn_enemy(random_room_tile)
		b = false
