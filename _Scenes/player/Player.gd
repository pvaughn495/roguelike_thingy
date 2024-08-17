extends StaticBody2D
class_name Player

const INPUT_DELAY = 0.1

@export var health : Health


const vision_range = Vector2i(10, 6)
var hold_timer_bool = true
var experience : int
var level: int
var exp_to_level: int


@onready var equipment := Equipment.new()
@onready var inventory := Inventory.new()
@onready var stats := CharacterStats.new()

signal move_player
signal stats_changed
signal exp_changed
signal leveled_up
signal died
# Called when the node enters the scene tree for the first time.
func _ready()->void:
	equipment.equip_changed.connect(handle_equipment_change)

func reset_player()->void:
	level = 0
	experience = 0
	exp_to_level = 0
	equipment.reset_equipment()
	inventory.reset_inventory()

func prepare_pc()->void:
	equipment.reset_equipment()
	inventory.reset_inventory()
	health.set_max_health(10)
	health.set_health(10)
	var wep = Item.new()
	wep.item_class = &"Axe"
	inventory.add_item_to_bag(wep)
	var wep2 = Item.new()
	wep2.item_class = &"Sword"
	inventory.add_item_to_bag(wep2)
	var potion = Item.new()
	potion.item_class = "Potion"
	inventory.add_item_to_bag(potion)
	var scroll1 = Item.new()
	scroll1.item_class = "Fireball"
	inventory.add_item_to_bag(scroll1)
	var scroll2 = Item.new()
	scroll2.item_class = "FairyFire"
	inventory.add_item_to_bag(scroll2)
	var scroll3 = Item.new()
	scroll3.item_class = "Missile"
	inventory.add_item_to_bag(scroll3)
	level = 1
	exp_to_level = get_exp_to_level()
	stats.process_level(level)
	stats.update_stats(equipment.get_stats())
	stats_changed.emit(stats)
	yell_at_hud()


func _unhandled_input(event:InputEvent)->void:
	event.is_echo()
	if event.is_action_pressed("Up", true):
		get_viewport().set_input_as_handled()
		move(Vector2i.UP)
		return
	if event.is_action_pressed("Down", true):
		get_viewport().set_input_as_handled()
		move(Vector2i.DOWN)
		return
	if event.is_action_pressed("Left", true):
		get_viewport().set_input_as_handled()
		move(Vector2i.LEFT)
		return
	if event.is_action_pressed("Right", true):
		get_viewport().set_input_as_handled()
		move(Vector2i.RIGHT)
		return
	if event.is_action_pressed("SpaceBar", true):
		get_viewport().set_input_as_handled()
		move(Vector2i.ZERO)
		return
	if event.is_action_pressed("Action", true):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Escape", true):
		get_viewport().set_input_as_handled()
		return

func move(direction : Vector2i)->void:
	if !hold_timer_bool: return
	
	hold_timer_bool = false
	move_player.emit(direction)
	await get_tree().create_timer(INPUT_DELAY).timeout
	hold_timer_bool = true

func take_damage(damage: int)->void:
	health.reduce_health(max(0, damage - stats.arm))

func get_attack_pattern()->String:
	if equipment.weapon_slot:
		return Data.ITEMS[equipment.weapon_slot.item_class]["Atk_Pattern"]
	else: return "Orthogonal"

func get_attack_range()->int:
	if equipment.weapon_slot:
		return Data.ITEMS[equipment.weapon_slot.item_class]["Range"]
	else: return 1

func _on_health_out_of_health()->void:
	died.emit()

func connect_health_signals(health_change_callable: Callable, max_health_change_callable: Callable)->void:
	var hcc := health.health_changed.get_connections()
	var mhc := health.max_health_changed.get_connections()
	if hcc.size() == 0:
		health.health_changed.connect(health_change_callable)
	else:
		if hcc[0]["callable"] != health_change_callable:
			health.health_changed.disconnect(hcc[0]["callable"])
			health.health_changed.connect(health_change_callable)
	if mhc.size() == 0:
		health.max_health_changed.connect(max_health_change_callable)
	else:
		if mhc[0]["callable"] != max_health_change_callable:
			health.max_health_changed.disconnect(mhc[0]["callable"])
			health.max_health_changed.connect(max_health_change_callable)

func connect_hud(health_change_callable: Callable, max_health_change_callable: Callable,
	exp_change_callable: Callable, level_change_callable: Callable, stats_changed_callable : Callable)->void:
	var hcc := health.health_changed.get_connections()
	var mhc := health.max_health_changed.get_connections()
	var ecc := exp_changed.get_connections()
	var lcc := leveled_up.get_connections()
	var scc := stats_changed.get_connections()
	if hcc.size() == 0:
		health.health_changed.connect(health_change_callable)
	else:
		if hcc[0]["callable"] != health_change_callable:
			health.health_changed.disconnect(hcc[0]["callable"])
			health.health_changed.connect(health_change_callable)
	if mhc.size() == 0: health.max_health_changed.connect(max_health_change_callable)
	else:
		if mhc[0]["callable"] != max_health_change_callable:
			health.max_health_changed.disconnect(mhc[0]["callable"])
			health.max_health_changed.connect(max_health_change_callable)
	if ecc.size() == 0: exp_changed.connect(exp_change_callable)
	else:
		if ecc[0]["callable"] != exp_change_callable:
			exp_changed.disconnect(ecc[0]["callable"])
			exp_changed.connect(exp_change_callable)
	if lcc.size() == 0: leveled_up.connect(level_change_callable)
	else:
		if lcc[0]["callable"] != level_change_callable:
			leveled_up.disconnect(lcc[0]["callable"])
			leveled_up.connect(level_change_callable)
	if scc.size() == 0: stats_changed.connect(stats_changed_callable)
	else:
		if scc[0]["callable"] != stats_changed_callable:
			stats_changed.disconnect(scc[0]["callable"])
			stats_changed.connect(stats_changed_callable)

func connect_inventory_signal(inventory_change_callable: Callable)->void:
	var connections := inventory.inventory_changed.get_connections()
	var already_connected = false
	for connection in connections:
		if connection["callable"] != inventory_change_callable:
			inventory.inventory_changed.disconnect(connection["callable"])
		else: already_connected = true
	if !already_connected: inventory.inventory_changed.connect(inventory_change_callable)
	

#func conntect_equipment_signal(equipment_change_callable: Callable, 
	#stats_changed_callable: Callable)->void:
	#var connections := equipment.equip_changed.get_connections()
	#var already_connected = false
	#for connection in connections:
		#if connection["callable"] != equipment_change_callable:
			#inventory.inventory_changed.disconnect(connection["callable"])
		#else: already_connected = true
	#if !already_connected: equipment.equip_changed.connect(equipment_change_callable)
	#
	#already_connected = false
	#connections = stats_changed.get_connections()
	#for connection in connections:
		#if connection["callable"] != stats_changed_callable:
			#stats_changed.disconnect(connection["callable"])
		#else: already_connected = true
	#if not already_connected: stats_changed.connect(stats_changed_callable)

func handle_equipment_change(equiped_item: Item, unequiped_item: Item)->void:
	stats.update_stats(equipment.get_stats())
	inventory.del_item_from_bag(equiped_item.bag_index)
	if unequiped_item: inventory.add_item_to_bag(unequiped_item)
	stats.process_level(level)
	stats_changed.emit(stats)

func collect_item(item: Item)->void:
	inventory.add_item_to_bag(item)

func consume_item(item: Item)->void:
	if Data.ITEMS[item.item_class]["Type"] != "Consumable":
		print("Error: attempting to consume ", item.item_class)
		return
	
	var heal_amt = Data.ITEMS[item.item_class].get("Heal", 0)
	heal_amt += item.modifiers.get("Heal", 0)
	
	if heal_amt > 0:
		health.heal(heal_amt)
	
	inventory.del_item_from_bag(item.bag_index)

func yell_at_hud()->void:
	exp_to_level = get_exp_to_level()
	health.heal(0)
	health.increase_max_health(0)
	stats.process_level(level)
	stats_changed.emit(stats)
	get_exp(0)
	
	leveled_up.emit(level)

func get_player_bag_count()->int:
	return inventory.get_bag_count()

func get_exp_to_level()->int:
	if level < 12: return 4*level + 2
	elif level < 24: return 8*level - 42
	elif level < 36: return 16*level - 226
	else: return 32*level-786

func get_exp(gained_exp : int)->void:
	experience += gained_exp
	if experience > exp_to_level:
		level += 1
		experience -= exp_to_level
		exp_to_level = get_exp_to_level()
		level_up()
	exp_changed.emit(experience, exp_to_level, gained_exp)

func level_up()->void:
	leveled_up.emit(level)
	stats.process_level(level)
	match level%4:
		1: pass # atk + 1
		2: 
			if health.get_max_health() < 28: health.increase_max_health(1)
			health.heal(1) # max_health + 1, health + 1
		3: pass #res + 1
		0: pass # armor + 1
	stats_changed.emit(stats)
