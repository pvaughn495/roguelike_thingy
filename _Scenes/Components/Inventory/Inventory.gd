extends Resource
class_name Inventory

const MAX_BAG_SPACE = 32

@export var bag_items : Array[Item]

signal inventory_changed

func reset_inventory():
	bag_items.resize(0)
	inventory_changed.emit()

func add_item_to_bag(new_item: Item):
	new_item.bag_index = bag_items.size()
	bag_items.append(new_item)
	inventory_changed.emit()
	print("inventory changed emited")

func del_item_from_bag(index: int):
	bag_items.remove_at(index)
	for i in range(index, bag_items.size()):
		bag_items[i].bag_index = i
	inventory_changed.emit()

func all_of_type(item_type: StringName):
	return bag_items.filter(func(item:Item): 
		if Data.ITEMS[item.item_class]["Type"] == item_type: return true
		else: return false)

func get_bag_count()->int:
	return bag_items.size()
