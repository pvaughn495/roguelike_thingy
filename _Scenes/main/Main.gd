extends Node2D

const TILE_CENTER_OFFSET = Vector2(-4.0,-4.0)
const SHADOW = Vector2i(1,1)
const SHADOW_LAYER = 3

@export var player : Player
@export var tilemap : TileMap
@export var camera : Camera2D
@export var enemy_scene : PackedScene
@export var hud : HUD
@export var equipmenu : EquipMenu
@export var invenmenu : InventoryMenu


var astar_offset : Vector2i
var rooms : Array[Rect2i]
var dungeon_depth : int


@onready var enemy_list : Array[Enemy] = []
@onready var enemy_tile_location_list : Array[Vector2i] = []
@onready var trigger_manager := TriggerManager.new(tilemap)
@onready var astar_map := AStarPath.new()
@onready var light_map := MatrixI.new(0, 0, 0)

## turn flow:
## 1. player moves
## 2. enemies move
## 3. ???
## 4. profit


var turn_state = 0 #0: system, 1: player, 2: enemy
var menu_state = 0 #0: no menu, 1. inventory, 2: equipment
var active = false

# Called when the node enters the scene tree for the first time.
func _ready():
	dungeon_depth = 0
	make_new_level()
	equipmenu.equipped_item.connect(_on_equip_menu_equip)
	player.stats_changed.connect(equipmenu.update_stats)
	player.died.connect(_on_player_died)
	connect_player_hb_hud()
	connect_player_inventory()
	player.prepare_pc()
	turn_state = 1
	active = true
	

func _physics_process(_delta):
	if enemy_list.size() < 10+dungeon_depth*2 and active:
		spawn_random_enemy()

func _input(event: InputEvent):
	if turn_state == 2: return
	
	if event.is_action_pressed("Character"):
		get_viewport().set_input_as_handled()
		match menu_state:
			0:
				turn_state = 0
				menu_state = 2
				equipmenu.visible = true
				equipmenu.wep_dropdown.grab_focus()
				return
			1:
				menu_state = 2
				equipmenu.visible = true
				invenmenu.visible = false
				equipmenu.wep_dropdown.grab_focus()
				return
			2:
				turn_state = 1
				menu_state = 0
				equipmenu.visible = false
				return
	if event.is_action_pressed("Inventory"):
		get_viewport().set_input_as_handled()
		match menu_state:
			0:
				turn_state = 0
				menu_state = 1
				invenmenu.visible = true
				invenmenu.itemlist.grab_focus()
				return
			1: 
				turn_state = 1
				menu_state = 0
				invenmenu.visible = false
				return
			2:
				menu_state = 1
				equipmenu.visible = false
				invenmenu.visible = true
				return
	
	if event.is_action("Escape"):
		get_viewport().set_input_as_handled()
		if menu_state == 2:
			menu_state = 0
			turn_state = 1
			equipmenu.visible = false
			return
		match menu_state:
			1:
				turn_state = 1
				menu_state = 0
				invenmenu.visible = false
				return
			2:
				turn_state = 1
				menu_state = 0
				equipmenu.visible = false
				return


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
	var new_trigger = trigger_manager.get_trigger_from_map(new_tile_pos)
	## if attackable enemies:
	var enemy_indexes: Array[int] = []
	if direction:
		for tile in AttackPatterns.get_attacked_tiles(tilemap.local_to_map(player.position), direction,
			player.get_attack_pattern(), player.get_attack_range()):
			enemy_indexes.append(enemy_tile_location_list.find(tile))
	else: enemy_indexes.append(-1)
	if enemy_indexes.max() >= 0:
		print(enemy_indexes)
		for enemy_index in enemy_indexes:
			if enemy_index >= 0: enemy_list[enemy_index].take_damage(player.stats.atk)
		
	elif astar_map.map.get_from_v(new_tile_pos-astar_offset):
		if new_trigger:
			match new_trigger.type:
				"Stair" : 
					make_new_level()
					return
				"Trap" : 
					new_trigger.activate(player)
					trigger_manager.delete_trigger(new_trigger.index)
				"Chest" : 
					new_trigger.activate(player)
					trigger_manager.delete_trigger(new_trigger.index)
		
		if turn_state == 1:
			clear_player_fov()
			move_entity_to_tile(player, new_tile_pos)
			player_fov()
			move_cam_to_player()
	else: return
	turn_state = 2
	enemy_turn()


func move_entity_to_tile(entity : Node2D, new_tile_pos: Vector2i):
	if entity == player: print("Player moved to ", new_tile_pos)
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
			if light_map.get_from_coord(tilemap.local_to_map(enemy.position)- astar_offset)-enemy.vision>=0:
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
	player.take_damage(enemy.atk)
	print("enemy ", enemy, " attacks player!")

func move_cam_to_player():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(camera, "position", player.position, 0.5)

func make_new_level():
	## clear the old level
	tilemap.clear()
	for enemy in enemy_list:
		enemy.queue_free()
	enemy_list.resize(0)
	enemy_tile_location_list.resize(0)
	trigger_manager.reset()
	
	
	## fire up the dungeon generator
	var dun_gen = DungeonGenerator.new()
	dun_gen.generate_dungeon(9, 9, 11)
	dun_gen.set_dungeon_in_tilemap(tilemap)
	rooms = dun_gen.rooms.duplicate()
	dun_gen.define_room_types()
	var temp_room = rooms[dun_gen.distance_from_center[-1].y]
	trigger_manager.add_trigger(temp_room.get_center(), "Stair")
	
	dungeon_depth += 1
	## Set the chests
	for i in range(-4,-1):
		temp_room = rooms[dun_gen.distance_from_center[i].y]
		trigger_manager.add_trigger(temp_room.get_center(), "Chest")
	
	move_entity_to_tile(player, dun_gen.rooms[dun_gen.distance_from_center[0].y].get_center())
	move_cam_to_player()
	tilemap.set_cell(1, dun_gen.rooms[dun_gen.distance_from_center[0].y].get_center(), 0,
		DungeonGenerator.DUN_DICT["Interior"]["Stair_UP"])
	
	
	## set the pathfinding map and light map
	var tilemap_rect = tilemap.get_used_rect()
	for x in range(tilemap_rect.position.x, tilemap_rect.end.x + 1):
		for y in range(tilemap_rect.position.y, tilemap_rect.end.y + 1):
			tilemap.set_cell(SHADOW_LAYER, Vector2i(x,y), 0, SHADOW, 1)
	astar_map.map = dun_gen.get_astar_map(tilemap_rect)
	astar_offset = tilemap_rect.position
	light_map.clear()
	light_map.resize(tilemap_rect.size.y, tilemap_rect.size.x)
	player_fov()
	turn_state = 1
	hud.dungeon_depth_label.text = str(dungeon_depth)


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
	new_enemy.set_enemy_type(enemy_type)
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
		spawn_enemy(random_room_tile, Data.ENEMY_GROUPS[((dungeon_depth-1)%8)/2].pick_random())
		b = false

func neighbors_and_weights(source : Vector2i, location: Vector2i)->Array:
	
	var delta = location - source
	## case: 1: |dx| = |dy|, 2: dx = 0 or dy = 0, 3: |dx| > |dy|, 4: |dx| < |dy|
	
	if abs(delta.x) == abs(delta.y):
		delta = delta.sign()
		return [[location + delta, 1],
			[Vector2i(location.x, location.y + delta.y), 2],
			[Vector2i(location.x + delta.x, location.y), 2]]
	if delta.x == 0:
		delta = delta.sign()
		return [[location + delta, 1],
			[Vector2i(location.x + 1, location.y + delta.y), 2],
			[Vector2i(location.x - 1, location.y + delta.y), 2]]
	if delta.y == 0:
		delta = delta.sign()
		return [[location + delta, 1],
			[Vector2i(location.x + delta.x, location.y + 1), 2],
			[Vector2i(location.x + delta.x, location.y - 1), 2]]
	if abs(delta.x) > abs(delta.y):
		delta = delta.sign()
		return [[location + delta, 2],
			[Vector2i(location.x + delta.x, location.y), 2]]
	if abs(delta.x) < abs(delta.y):
		delta = delta.sign()
		return [[location + delta, 2],
			[Vector2i(location.x, location.y + delta.y), 2]]
	return []

@warning_ignore("shadowed_global_identifier")
func calc_fov(source: Vector2i, range: Vector2i):
	
	var set_light_map = func(loc: Vector2i, light: int):
		light_map.set_at_coord(loc - astar_offset, light)
	var add_light_map = func(loc: Vector2i, light: int):
		light_map.add_at_coord(loc- astar_offset, light)
	var get_light_map = func(loc: Vector2i)->int:
		return light_map.get_from_coord(loc - astar_offset)
	var get_walkable = func(loc: Vector2i)->bool:
		return astar_map.map.get_from_v(loc - astar_offset)
	
	set_light_map.call(source, 8)
	var frontier : Array[Vector2i] = []
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i == 0 and  j == 0: continue
			var next = source + Vector2i(i, j)
			set_light_map.call(next, 8)
			if get_walkable.call(next): #only add to queue if the cell lets light through
				frontier.append(source + Vector2i(i,j))
	
	while(frontier.size() > 0):
		var next_frontier : Array[Vector2i] = []
		for i in frontier.size():
			var next = frontier.pop_back()
			var next_light = get_light_map.call(next)
			for neighbor_weight in neighbors_and_weights(source, next):
				var abs_dif = (source - neighbor_weight[0]).abs()
				if abs_dif.x > range.x or abs_dif.y > range.y: continue
				var lightval = next_light/neighbor_weight[1]
				if lightval <= 0: continue
				if next_frontier.has(neighbor_weight[0]):
					add_light_map.call(neighbor_weight[0], lightval)
				else:
					add_light_map.call(neighbor_weight[0], lightval)
					if get_walkable.call(neighbor_weight[0]):
						next_frontier.append(neighbor_weight[0])
		frontier = next_frontier.duplicate()

func player_fov():
	var player_tile = tilemap.local_to_map(player.position)
	calc_fov(player_tile, player.vision_range)
	var player_vision_rect = Rect2i(player_tile - player.vision_range, player.vision_range*2)
	for x in range(player_vision_rect.position.x, player_vision_rect.end.x + 1):
		for y in range(player_vision_rect.position.y, player_vision_rect.end.y + 1):
			var tile_loc = Vector2i(x,y) - astar_offset
			var lightval = light_map.get_from_coord(tile_loc)
			#light_map.set_at_coord(tile_loc, 0)
			tilemap.set_cell(SHADOW_LAYER, Vector2i(x,y), 0, SHADOW, lightval+1)


func clear_player_fov():
	var player_tile = tilemap.local_to_map(player.position)
	var player_vision_rect = Rect2i(player_tile - player.vision_range, player.vision_range*2)
	for x in range(player_vision_rect.position.x, player_vision_rect.end.x + 1):
		for y in range(player_vision_rect.position.y, player_vision_rect.end.y + 1):
			var tile_loc = Vector2i(x,y) - astar_offset
			var lightval = light_map.get_from_coord(tile_loc)
			light_map.set_at_coord(tile_loc, 0)
			if lightval:pass
			tilemap.set_cell(SHADOW_LAYER, Vector2i(x,y), 0, SHADOW, 1)

func connect_player_hb_hud():
	player.connect_health_signals(hud.update_health, hud.update_max_health)

func connect_player_inventory():
	player.connect_inventory_signal(_on_player_inventory_changed)

func _on_player_inventory_changed():
	print("update invetory stuff")
	invenmenu.update_inventory(player.inventory)
	equipmenu.update_dropdowns(player.inventory, player.equipment)

func _on_equip_menu_equip(item):
	player.equipment.equip_item(item)
	hud.update_wep_textrect(equipmenu.wep_dropdown.get_item_icon(equipmenu.wep_dropdown.get_selected_id()))

func _on_player_died():
	active = false
	turn_state = 0
	player.prepare_pc()
	hud.update_wep_textrect(null)
	dungeon_depth = 0
	make_new_level()
	turn_state = 1
	active = true


