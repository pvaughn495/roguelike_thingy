extends RefCounted
class_name Equipment

var armor_slot: Item
var weapon_slot: Item
var ring_slot: Item
var shield_slot : Item

signal equip_changed

func reset_equipment():
	armor_slot = null
	weapon_slot = null
	ring_slot = null
	shield_slot = null

func get_stats()->Dictionary:
	var stat_dict = {}
	var equipment : Array[Item] = [armor_slot, weapon_slot, ring_slot, shield_slot]
	
	for item in equipment:
		if !item: continue
		match Data.ITEMS[item.item_class]["Type"]:
			"Armor": 
				if stat_dict.has("Arm"): stat_dict["Arm"] += Data.ITEMS["Armor"]["Arm"]
				else: stat_dict["Arm"] = Data.ITEMS["Armor"]["Arm"]
			"Weapon":
				if stat_dict.has("Atk"): stat_dict["Atk"] += Data.ITEMS[item.item_class]["Atk"]
				else: stat_dict["Atk"] = Data.ITEMS[item.item_class]["Atk"]
			_: pass
		
		for mod in item.modifiers.keys():
			if stat_dict.has(mod): stat_dict[mod] += item.modifiers[mod]
			else: stat_dict[mod] = item.modifiers[mod]
	
	return stat_dict

func equip_armor(new_armor: Item)->Item:
	if new_armor.item_class != "Armor":
		print("Error: attemping to equip non-armor in armor slot!")
		return
	var old_armor = armor_slot
	armor_slot = new_armor
	equip_changed.emit(new_armor, old_armor)
	return old_armor

func equip_weapon(new_weapon: Item)->Item:
	if Data.ITEMS[new_weapon.item_class]["Type"] != "Weapon":
		print("Error: attemping to equip non-weapon in weapon slot!")
		return
	var old_weapon = weapon_slot
	weapon_slot = new_weapon
	equip_changed.emit(new_weapon, old_weapon)
	return old_weapon

func equip_ring(new_ring: Item)->Item:
	if new_ring.item_class != "Ring":
		print("Error: attemping to equip non-ring in ring slot!")
		return
	var old_ring = ring_slot
	ring_slot = new_ring
	equip_changed.emit(new_ring, old_ring)
	return old_ring

func equip_shield(new_shield: Item)->Item:
	if new_shield.item_class != "Shield":
		print("Error: attemping to equip non-shield in shield slot!")
		return
	var old_shield = shield_slot
	shield_slot = new_shield
	equip_changed.emit(new_shield, old_shield)
	return old_shield

func equip_item(item):
	match Data.ITEMS[item.item_class]["Type"]:
		"Weapon": equip_weapon(item)
		"Armor": equip_armor(item)
		"Ring": equip_ring(item)
