extends Trigger
class_name Chest


@warning_ignore("shadowed_variable")
func _init(map_location : Vector2i = Vector2i.ZERO, index: int = 0)->void:
	if map_location or index:
		super.set_trigger(map_location, index, "Chest")

func activate(entity = null, dungeon_depth: int = 0)->void:
	if !entity: return
	if entity.has_method("collect_item"):
		entity.collect_item(generate_item(dungeon_depth))
	
	super.delete_trigger()
	

func generate_item(dungeon_depth : int = 0)->Item:
	var item = Item.new()
	
	var rng = randf_range(0.0, 99.9)
	var chance : Array
	if dungeon_depth >= 10: chance = Data.LOOT_RATES.back()
	else: chance = Data.LOOT_RATES[(dungeon_depth-1)/3]
	var item_type
	if rng <= chance[0]: item_type = 0
	elif rng <= chance[1]: item_type = 1
	elif rng <= chance[2]: item_type = 2
	elif rng <= chance[3]: item_type = 3
	elif rng <= chance[4]: item_type = 4
	else: item_type = 5
	
	match item_type:
		0: item.item_class = ["Sword", "Club"].pick_random()
		1: item.item_class = ["Axe", "Spear"].pick_random() 
		2: item.item_class = "Armor"
		3: item.item_class = "Ring"
		4: item.item_class = "Potion"
		5: item.item_class = ["Fireball", "FairyFire", "Missile"]
	
	return item
