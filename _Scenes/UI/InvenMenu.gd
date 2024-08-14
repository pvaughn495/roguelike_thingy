extends Control
class_name InventoryMenu

var activated_item : Item

@export var itemlist : ItemList
@export var texture : Texture2D
@export var item_selected_popup : PopupMenu

signal consume_item
signal equip_item
signal cast_item

func _ready():
	itemlist.item_activated.connect(_on_item_activated)
	item_selected_popup.index_pressed.connect(_on_popup_selection)
	pass

func update_inventory(inventory: Inventory):
	print(inventory.bag_items.size())
	itemlist.clear()
	for item in inventory.bag_items:
		var atlas = AtlasTexture.new()
		atlas.set_atlas(texture)
		atlas.set_region(tile_to_rect(Data.ITEMS[item.item_class]["Atlas"]))
		itemlist.add_item(item.item_class, atlas)
		itemlist.set_item_metadata(itemlist.item_count -1, item)

func _on_item_activated(idx: int):
	activated_item = itemlist.get_item_metadata(idx)
	if !activated_item: return
	
	var text : String
	match Data.ITEMS[activated_item.item_class]["Type"]:
		"Weapon" : text = "Equip"
		"Armor" : text = "Equip"
		"Ring" : text = "Equip"
		"Shield" : text = "Equip"
		"Consumable": text = "Use"
		"Spell" : text = "Cast"
		_ : text = ""
	
	item_selected_popup.set_item_text(0, text)
	item_selected_popup.visible = true
	item_selected_popup.set_focused_item(0)

func _on_popup_selection(idx: int):
	match idx:
		1: activated_item = null
		0: 
			match item_selected_popup.get_item_text(0):
				"Use": 
					print("Use ", activated_item.item_class)
					consume_item.emit(activated_item)
				"Equip": 
					print("Equip ", activated_item.item_class)
					equip_item.emit(activated_item)
				"Cast":
					print("Cast ", activated_item.item_class)
					cast_item.emit(activated_item)

func tile_to_rect(tile: Vector2i)->Rect2i:
	return Rect2(tile*9, 8*Vector2i.ONE)
