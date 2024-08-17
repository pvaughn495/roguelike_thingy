extends Node2D

const TILE_CENTER_OFFSET = Vector2(-4.0,-4.0)
const SHADOW = Vector2i(1,1)
const SHADOW_LAYER = 3

@export var player : Player
@export var tilemap : TileMap
@export var camera : Camera2D
@export var enemy_scene : PackedScene

@export_category("UI")
@export var hud : HUD
@export var equipmenu : EquipMenu
@export var invenmenu : InventoryMenu
@export var rangedmenu : RangedActionUI
@export var escmenu : EscMenu
@export var mainmenu : MainMenu
@export var timermenu : Timer


var astar_offset : Vector2i
var rooms : Array[Rect2i]
var connections: Array[Vector2i]
var dungeon_depth : int
var save_slot : String


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
var menu_state = 4 #0: no menu, 1. inventory, 2: equipment, 3: ranged, 4: mainmenu, 5: esc menu
var active = false

# Called when the node enters the scene tree for the first time.
func _ready()->void:
	connect_stuff()


func connect_stuff()->void:
	if !equipmenu.equipped_item.is_connected(_on_equip_menu_equip):
		equipmenu.equipped_item.connect(_on_equip_menu_equip)
	if !invenmenu.equip_item.is_connected(_on_equip_menu_equip):
		invenmenu.equip_item.connect(_on_equip_menu_equip)
	if !invenmenu.consume_item.is_connected(_on_inventory_consume):
		invenmenu.consume_item.connect(_on_inventory_consume)
	if !invenmenu.cast_item.is_connected(_on_inventory_cast):
		invenmenu.cast_item.connect(_on_inventory_cast)
	if !rangedmenu.get_valid_targets.is_connected(get_valid_range_target_tiles):
		rangedmenu.get_valid_targets.connect(get_valid_range_target_tiles)
	if !rangedmenu.spell_cast.is_connected(_on_ranged_ui_cast):
		rangedmenu.spell_cast.connect(_on_ranged_ui_cast)
	if !player.stats_changed.is_connected(equipmenu.update_stats):
		player.stats_changed.connect(equipmenu.update_stats)
	if !player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	connect_player_hb_hud()
	connect_player_inventory()
	if !mainmenu.new_game.is_connected(new_game):
		mainmenu.new_game.connect(new_game)
	if !mainmenu.load_game.is_connected(load_main):
		mainmenu.load_game.connect(load_main)
	if !escmenu.return_to_game.is_connected(_on_escape_menu_closed):
		escmenu.return_to_game.connect(_on_escape_menu_closed)
	if !escmenu.save_and_menu.is_connected(_on_escape_menu_save_main):
		escmenu.save_and_menu.connect(_on_escape_menu_save_main)
	#escmenu.save_and_quit.connect()


func load_main(file_name: String)->void:
	
	save_slot = file_name
	clear_level()
	load_game(file_name)
	connect_stuff()
	mainmenu.set_visible(false)
	turn_state = 1
	menu_state = 0
	active = true

func new_game(file_name : String)->void:
	player.reset_player()
	save_slot = file_name
	clear_level()
	make_new_level()
	player.prepare_pc()
	turn_state = 1
	active = true
	mainmenu.set_visible(false)
	menu_state = 0

func _physics_process(_delta)->void:
	if !active: return
	if enemy_list.size() < 10+dungeon_depth*2 and active:
		spawn_random_enemy()

func _input(event: InputEvent)->void:
	if !timermenu.is_stopped(): return
	if turn_state == 2: return
	
	if event.is_action_pressed("Character"):
		get_viewport().set_input_as_handled()
		timermenu.start()
		match menu_state:
			0:
				turn_state = 0
				menu_state = 2
				equipmenu.update_dropdowns(player.inventory, player.equipment)
				equipmenu.visible = true
				equipmenu.wep_dropdown.grab_focus()
				return
			1:
				menu_state = 2
				equipmenu.update_dropdowns(player.inventory, player.equipment)
				equipmenu.visible = true
				invenmenu.visible = false
				equipmenu.wep_dropdown.grab_focus()
				return
			2:
				turn_state = 1
				menu_state = 0
				equipmenu.visible = false
				return
			_: return
	if event.is_action_pressed("Inventory"):
		get_viewport().set_input_as_handled()
		timermenu.start()
		match menu_state:
			0:
				turn_state = 0
				menu_state = 1
				invenmenu.update_inventory(player.inventory)
				invenmenu.visible = true
				invenmenu.itemlist.grab_focus()
				#invenmenu.itemlist.select(0)
				return
			1: 
				turn_state = 1
				menu_state = 0
				invenmenu.visible = false
				return
			2:
				menu_state = 1
				equipmenu.visible = false
				invenmenu.update_inventory(player.inventory)
				invenmenu.visible = true
				invenmenu.itemlist.grab_focus()
				invenmenu.itemlist.select(0)
				return
			_: return
	
	if event.is_action("Escape"):
		timermenu.start()
		get_viewport().set_input_as_handled()
		match menu_state:
			0: # open the esc menu
				timermenu.set_paused(true)
				turn_state = 0
				menu_state = 5
				escmenu.set_visible(true)
				escmenu.grab_foc()
				return
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
			3:
				menu_state = 0
				turn_state = 1
				rangedmenu.visible = false
				rangedmenu.reset()
				rangedmenu.process_mode = Node.PROCESS_MODE_DISABLED
				return
			4:
				return
			5: 
				return #close the esc menu



func _on_player_move_player(direction: Vector2i)->void:
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
		enemy_indexes.sort()
		enemy_indexes.reverse()
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
					new_trigger.activate(player, dungeon_depth)
					trigger_manager.delete_trigger(new_trigger.index)
		
		if turn_state == 1:
			clear_player_fov()
			move_entity_to_tile(player, new_tile_pos)
			player_fov()
			move_cam_to_player()
	else: return
	turn_state = 2
	enemy_turn()


func move_entity_to_tile(entity : Node2D, new_tile_pos: Vector2i)->void:
	entity.position = tilemap.map_to_local(new_tile_pos) #+ TILE_CENTER_OFFSET

func enemy_turn()->void:
	if turn_state == 2:
		turn_state = 1
	else: 
		print("Error: enemy turn called, state: ", turn_state)
		return
	
	var player_tile = tilemap.local_to_map(player.position)
	var enemies = $Enemies.get_children()
	for enemy in enemies:
		enemy_action(enemy, player_tile)

func enemy_action(enemy : Enemy, player_tile)->void:
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

func enemy_attack(enemy: Enemy)->void:
	player.take_damage(enemy.atk)

func get_enemy_tiles_in_range(search_range: int, nearest : bool = false)->Array[Vector2i]:
	var player_tile = tilemap.local_to_map(player.position)
	var good_list : Array[Vector2i] = []
	for tile in enemy_tile_location_list:
		if Norms.vector2i_l1(player_tile - tile) <= search_range:
			good_list.append(tile)
	if good_list.size() <= 1: return good_list
	else:
		good_list.sort_custom(func(tile1: Vector2i, tile2: Vector2i)->bool:
			if Norms.vector2i_l1(player_tile - tile2) < Norms.vector2i_l1(player_tile - tile1): return false
			else: return true)
		if nearest:
			good_list.resize(1)
			return good_list
		return good_list

func get_ranged_los_tiles(search_range:int)->Array[Vector2i]:
	var good_tiles : Array[Vector2i] = []
	var player_tile = tilemap.local_to_map(player.position)
	for x in range(-search_range, search_range + 1):
		for y in range(-search_range, search_range + 1):
			if abs(x) + abs(y) > search_range: continue
			var next = Vector2i(x,y)
			if (light_map.get_from_coord(next + player_tile - astar_offset)>=4 and 
			astar_map.map.get_from_v(next + player_tile - astar_offset)):
				good_tiles.append(next)
	
	return good_tiles

func get_valid_range_target_tiles(search_range: int, select_tiles: bool, nearest : bool = false)->void:
	if select_tiles:
		rangedmenu.set_tiles_and_emit(get_ranged_los_tiles(search_range))
	else:
		rangedmenu.set_tiles_and_emit(get_enemy_tiles_in_range(search_range, nearest))

func move_cam_to_player()->void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(camera, "position", player.position, 0.5)

func make_new_level()->void:
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
	connections = dun_gen.connections.duplicate()
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

func spawn_enemy(tile_location :Vector2i, enemy_type : String = "Rat")->void:
	var new_enemy : Enemy = enemy_scene.instantiate()
	new_enemy.position = tilemap.map_to_local(tile_location)
	$Enemies.add_child(new_enemy)
	new_enemy.index = enemy_list.size()
	new_enemy.set_enemy_type(enemy_type)
	enemy_list.append(new_enemy)
	enemy_tile_location_list.append(tile_location)
	new_enemy.dead.connect(_on_enemy_died)
	if dungeon_depth > 5:
		new_enemy.atk += (dungeon_depth - 5)/2
		new_enemy.health.increase_max_health((dungeon_depth-6)/2)
		new_enemy.health.heal((dungeon_depth-6)/2)

func _on_enemy_died(enemy_index : int)->void:
	player.get_exp(enemy_list[enemy_index].health.get_max_health())
	#call_deferred("del_enemy", enemy_index)
	del_enemy(enemy_index)

func del_enemy(enemy_index : int)->void:
	## book keeping for the list of enemies and their locations
	
	enemy_list.remove_at(enemy_index)
	enemy_tile_location_list.remove_at(enemy_index)
	## re-index each of the enemies in the list after the deleted entry
	for i in range(enemy_index, enemy_list.size()):
		enemy_list[i].index = i

func spawn_random_enemy()->void:
	var b = true
	while(b):
		var random_room = rooms.pick_random()
		if random_room.has_point(tilemap.local_to_map(player.position)): continue
		var random_room_tile = Vector2i(randi_range(random_room.position.x+1,random_room.end.x -2), 
			randi_range(random_room.position.y+1,random_room.end.y -2))
		if enemy_tile_location_list.has(random_room_tile): continue
		spawn_enemy(random_room_tile, get_random_enemy_type())
		b = false

func get_random_enemy_type()->String:
	var rng = randf_range(0.0, 99.9)
	var chance : Array
	if dungeon_depth >= 24: chance = Data.SPAWN_RATES_ENEMIES.back()
	else: chance = Data.SPAWN_RATES_ENEMIES[dungeon_depth/2]
	
	if rng <= chance[0]: return Data.ENEMY_GROUPS[0].pick_random()
	elif rng <= chance[1]: return Data.ENEMY_GROUPS[1].pick_random()
	elif rng <= chance[2]: return Data.ENEMY_GROUPS[2].pick_random()
	else: return Data.ENEMY_GROUPS[3].pick_random()
	

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
func calc_fov(source: Vector2i, range: Vector2i)->void:
	
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

func player_fov()->void:
	var player_tile = tilemap.local_to_map(player.position)
	calc_fov(player_tile, player.vision_range)
	var player_vision_rect = Rect2i(player_tile - player.vision_range, player.vision_range*2)
	for x in range(player_vision_rect.position.x, player_vision_rect.end.x + 1):
		for y in range(player_vision_rect.position.y, player_vision_rect.end.y + 1):
			var tile_loc = Vector2i(x,y) - astar_offset
			var lightval = light_map.get_from_coord(tile_loc)
			#light_map.set_at_coord(tile_loc, 0)
			tilemap.set_cell(SHADOW_LAYER, Vector2i(x,y), 0, SHADOW, lightval+1)


func clear_player_fov()->void:
	var player_tile = tilemap.local_to_map(player.position)
	var player_vision_rect = Rect2i(player_tile - player.vision_range, player.vision_range*2)
	for x in range(player_vision_rect.position.x, player_vision_rect.end.x + 1):
		for y in range(player_vision_rect.position.y, player_vision_rect.end.y + 1):
			var tile_loc = Vector2i(x,y) - astar_offset
			var lightval = light_map.get_from_coord(tile_loc)
			light_map.set_at_coord(tile_loc, 0)
			if lightval:pass
			tilemap.set_cell(SHADOW_LAYER, Vector2i(x,y), 0, SHADOW, 1)

func connect_player_hb_hud()->void:
	player.connect_hud(hud.update_health, hud.update_max_health, hud.update_exp_bar,
		hud.update_level_label, equipmenu.update_stats)



func connect_player_inventory()->void:
	player.connect_inventory_signal(_on_player_inventory_changed)

func _on_player_inventory_changed()->void:
	invenmenu.update_inventory(player.inventory)
	equipmenu.update_dropdowns(player.inventory, player.equipment)

func _on_equip_menu_equip(item)->void:
	player.equipment.equip_item(item)
	hud.update_wep_textrect(equipmenu.wep_dropdown.get_item_icon(equipmenu.wep_dropdown.get_selected_id()))

func _on_inventory_consume(item: Item)->void:
	player.consume_item(item)

func _on_inventory_cast(item: Item)->void:
	menu_state = 3
	invenmenu.visible = false
	rangedmenu.process_mode = Node.PROCESS_MODE_INHERIT
	rangedmenu.prepare_ui(tilemap.local_to_map(player.position), item)
	rangedmenu.visible = true

func _on_ranged_ui_cast(item: Item, affected_tiles: Array[Vector2i])->void:
	var damage = Data.ITEMS[item.item_class]["Atk"]
	var enemy_idices = affected_tiles.map(func(a:Vector2i): return enemy_tile_location_list.find(a))
	enemy_idices.sort()
	enemy_idices.reverse()
	for enemy_idx in enemy_idices:
		if enemy_idx >= 0:
			enemy_list[enemy_idx].take_damage(damage + player.stats.res)
	
	player.inventory.del_item_from_bag(item.bag_index)
	rangedmenu.reset()
	rangedmenu.visible = false
	rangedmenu.process_mode = Node.PROCESS_MODE_DISABLED
	menu_state = 0
	turn_state = 1
	player.move(Vector2i.ZERO)

func _on_player_died()->void:
	active = false
	turn_state = 0
	player.prepare_pc()
	hud.update_wep_textrect(null)
	dungeon_depth = 0
	make_new_level()
	turn_state = 1
	active = true

func save_game(file_name : String)->void:
	var save = GameSave.new()
	save.rooms = rooms
	save.connections = connections
	save.depth = dungeon_depth
	save.astar_offset = astar_offset
	save.astar_map_contents = astar_map.map.contents
	save.astar_map_dimensions = Vector2i(astar_map.map.num_cols, astar_map.map.num_rows)
	save.enemy_tile_loc = enemy_tile_location_list
	save.enemy_atk.resize(enemy_list.size())
	save.enemy_max_health.resize(enemy_list.size())
	save.enemy_health.resize(enemy_list.size())
	for i in enemy_list.size():
		save.enemy_atk[i] = enemy_list[i].atk
		save.enemy_max_health[i] = enemy_list[i].health.get_max_health()
		save.enemy_health[i] = enemy_list[i].health.get_health()
	save.enemy_type.resize(enemy_list.size())
	for i in enemy_list.size():
		save.enemy_type[i] = enemy_list[i].enemy_type
	
	save.trigger_managaer = trigger_manager
	
	save.player_location = player.position
	save.player_health = player.health.get_health()
	save.player_max_health = player.health.get_max_health()
	save.player_inventory = player.inventory
	save.player_equipment = player.equipment
	save.player_exp = player.experience
	save.player_level = player.level
	
	save.save_game(file_name)

func load_game(file_name : String)->void:
	var save := GameSave.load_game(file_name)
	
	#set up the dungeon
	var dun_gen = DungeonGenerator.new()
	dun_gen.rooms = save.rooms
	rooms = save.rooms.duplicate()
	dun_gen.connections = save.connections
	connections = save.connections.duplicate()
	dun_gen.set_dungeon_in_tilemap(tilemap)
	dungeon_depth = save.depth
	hud.dungeon_depth_label.text = str(dungeon_depth)
	var map = MatrixB.new(save.astar_map_dimensions.y, save.astar_map_dimensions.x)
	map.contents = save.astar_map_contents
	astar_offset = save.astar_offset
	astar_map.map = map
	
	#set up enemies
	for i in save.enemy_tile_loc.size():
		spawn_enemy(save.enemy_tile_loc[i], save.enemy_type[i])
		enemy_list[i].atk = save.enemy_atk[i]
		enemy_list[i].health.set_max_health(save.enemy_max_health[i])
		enemy_list[i].health.set_health(save.enemy_health[i])
	
	trigger_manager = save.trigger_managaer
	trigger_manager.load_triggers(tilemap)
	#set up player
	move_entity_to_tile(player, tilemap.local_to_map(save.player_location))
	#player.inventory = save.player_inventory
	for item in save.player_inventory.bag_items:
		player.inventory.add_item_to_bag(item)
	#player.equipment = save.player_equipment
	player.equipment.equip_armor(save.player_equipment.armor_slot)
	player.equipment.equip_weapon(save.player_equipment.weapon_slot)
	if player.equipment.weapon_slot:
		hud.update_wep_textrect(equipmenu.wep_dropdown.get_item_icon(equipmenu.wep_dropdown.get_selected_id()))
	
	player.equipment.equip_ring(save.player_equipment.ring_slot)
	player.equipment.equip_shield(save.player_equipment.shield_slot)
	
	player.health.set_max_health(save.player_max_health)
	player.health.set_health(save.player_health)
	player.stats.update_stats(player.equipment.get_stats())
	player.level = save.player_level
	player.experience = save.player_exp
	player.yell_at_hud()
	equipmenu.update_dropdowns(player.inventory, player.equipment)
	equipmenu.update_stats(player.stats)
	invenmenu.update_inventory(player.inventory)
	move_cam_to_player()
	var tilemap_rect = tilemap.get_used_rect()
	for x in range(tilemap_rect.position.x, tilemap_rect.end.x + 1):
		for y in range(tilemap_rect.position.y, tilemap_rect.end.y + 1):
			tilemap.set_cell(SHADOW_LAYER, Vector2i(x,y), 0, SHADOW, 1)
	astar_map.map = dun_gen.get_astar_map(tilemap_rect)
	astar_offset = tilemap_rect.position
	light_map.clear()
	light_map.resize(tilemap_rect.size.y, tilemap_rect.size.x)
	player_fov()

func clear_level():
	dungeon_depth = 0
	tilemap.clear()
	for enemy in enemy_list:
		enemy.queue_free()
	enemy_list.resize(0)
	enemy_tile_location_list.resize(0)
	trigger_manager.reset()
	player.reset_player()
	hud.update_wep_textrect(null)
	rooms.resize(0)
	connections.resize(0)
	enemy_list.resize(0)
	enemy_tile_location_list.resize(0)

func _on_escape_menu_closed()->void:
	if timermenu.is_paused(): timermenu.set_paused(false)
	if escmenu.selection : return
	escmenu.visible = false
	menu_state = 0
	turn_state = 1

func _on_escape_menu_save_main()->void:
	turn_state = 0
	menu_state = 4
	save_game(save_slot)
	mainmenu.set_visible(true)







