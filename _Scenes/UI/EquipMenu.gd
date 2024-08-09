extends Control
class_name EquipMenu

@export var texture : Texture2D


@export_category("Equipment Dropdowns")
@export var wep_dropdown : OptionButton
@export var arm_dropdown : OptionButton
@export var ring_dropdown : OptionButton
@export var shld_dropdown : OptionButton

@export_category("Stats Labels")
@export var atk_label : Label
@export var arm_label : Label
@export var res_label : Label

var drop_dict := {"Weapon" = wep_dropdown, "Armor" = arm_dropdown, "Ring" = ring_dropdown,
	"Consumable" = shld_dropdown}

signal equipped_item

func _ready():
	wep_dropdown.item_selected.connect(equip_item.bind(wep_dropdown))
	arm_dropdown.item_selected.connect(equip_item.bind(arm_dropdown))
	ring_dropdown.item_selected.connect(equip_item.bind(ring_dropdown))
	clear_dropdowns()


func tile_to_rect(tile:Vector2i)->Rect2i:
	return Rect2i(tile*9, Vector2i(8,8))

func clear_dropdowns():
	wep_dropdown.clear()
	arm_dropdown.clear()
	ring_dropdown.clear()
	shld_dropdown.clear()

func set_item(dropdown: OptionButton, item_index: int, item_class : String):
	var atlas = AtlasTexture.new()
	atlas.set_atlas(texture)
	atlas.set_region(tile_to_rect(Data.ITEMS[item_class]["Atlas"]))
	dropdown.set_item_icon(item_index, atlas)
	dropdown.set_item_text(item_index, item_class)

func add_item(dropdown : OptionButton, item : Item):
	if !item:
		if !dropdown.item_count:
			dropdown.add_item("None")
			return
		else: return
	
	var item_class = item.item_class
	
	var atlas = AtlasTexture.new()
	atlas.set_atlas(texture)
	atlas.set_region(tile_to_rect(Data.ITEMS[item_class]["Atlas"]))
	dropdown.add_icon_item(atlas, item_class)
	dropdown.set_item_metadata(dropdown.item_count-1, item)

func update_dropdowns(inventory : Inventory, equipment: Equipment):
	clear_dropdowns()
	
	add_item(wep_dropdown, equipment.weapon_slot)
	add_item(arm_dropdown, equipment.armor_slot)
	add_item(ring_dropdown, equipment.ring_slot)
	add_item(shld_dropdown, equipment.shield_slot)
	
	for item in inventory.bag_items:
		match Data.ITEMS[item.item_class]["Type"]:
			"Weapon": add_item(wep_dropdown, item)
			"Armor": add_item(arm_dropdown, item)
			"Ring": add_item(ring_dropdown, item)
			"Shield": add_item(shld_dropdown, item)

func equip_item(drop_item_idx : int, dropdown: OptionButton):
	var item_metadata = dropdown.get_item_metadata(drop_item_idx)
	if item_metadata: equipped_item.emit(item_metadata)

func update_stats(stats: CharacterStats):
	atk_label.text = "Atk " + str(stats.atk)
	arm_label.text = "Arm " + str(stats.arm)
	res_label.text = "Res " + str(stats.res)



