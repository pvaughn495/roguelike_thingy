extends StaticBody2D
class_name Player

const INPUT_DELAY = 0.1

@export var health : Health

var vision_range = Vector2i(10, 6)
var hold_timer_bool = true



@onready var equipment := Equipment.new()
@onready var inventory := Inventory.new()
@onready var stats := CharacterStats.new()

signal move_player
signal stats_changed
signal died
# Called when the node enters the scene tree for the first time.
func _ready():
	equipment.equip_changed.connect(handle_equipment_change)
	
	

func prepare_pc():
	equipment.reset_equipment()
	inventory.reset_inventory()
	health.set_max_health(10)
	health.set_health(10)
	var wep = Item.new()
	wep.bag_index = 0
	wep.item_class = &"Axe"
	inventory.add_item_to_bag(wep)
	var wep2 = Item.new()
	wep2.bag_index = 0
	wep2.item_class = &"Sword"
	inventory.add_item_to_bag(wep2)
	var potion = Item.new()
	potion.bag_index = 1
	potion.item_class = "Potion"
	inventory.add_item_to_bag(potion)
	stats.update_stats(equipment.get_stats())


func _unhandled_input(event:InputEvent):
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

func move(direction : Vector2i):
	if !hold_timer_bool: return
	
	hold_timer_bool = false
	move_player.emit(direction)
	await get_tree().create_timer(INPUT_DELAY).timeout
	hold_timer_bool = true

func take_damage(damage: int):
	health.reduce_health(damage)

func get_attack_pattern()->String:
	if equipment.weapon_slot:
		return Data.ITEMS[equipment.weapon_slot.item_class]["Atk_Pattern"]
	else: return "Orthogonal"

func get_attack_range()->int:
	if equipment.weapon_slot:
		return Data.ITEMS[equipment.weapon_slot.item_class]["Range"]
	else: return 1

func _on_health_out_of_health():
	died.emit()

func connect_health_signals(health_change_callable: Callable, max_health_change_callable: Callable):
	health.health_changed.connect(health_change_callable)
	health.max_health_changed.connect(max_health_change_callable)

func connect_inventory_signal(inventory_change_callable: Callable):
	inventory.inventory_changed.connect(inventory_change_callable)
	

func conntect_equipment_signal(equipment_change_callable: Callable):
	equipment.equip_changed.connect(equipment_change_callable)

func handle_equipment_change(equiped_item: Item, unequiped_item: Item):
	stats.update_stats(equipment.get_stats())
	inventory.del_item_from_bag(equiped_item.bag_index)
	if unequiped_item: inventory.add_item_to_bag(unequiped_item)
	stats_changed.emit(stats)

func collect_item(item: Item):
	inventory.add_item_to_bag(item)
