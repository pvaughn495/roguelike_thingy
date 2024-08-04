extends Trigger
class_name Chest

@warning_ignore("shadowed_variable")
func _init(map_location, index):
	super.set_trigger(map_location, index, "Chest")

func activate(entity = null):
	if !entity: return
	if entity.has_method("collect_item"):
		entity.collect_item(generate_item())
	
	
	super.delete_trigger()
	

func generate_item()->Item:
	var item = Item.new()
	match randi_range(0, 4):
		0: item.item_class = ["Sword", "Club"].pick_random()
		1: item.item_class = ["Axe", "Spear"].pick_random() 
		2: item.item_class = "Armor"
		3: item.item_class = "Ring"
		4: item.item_class = "Potion"
	
	return item
