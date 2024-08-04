extends Control
class_name InventoryMenu


@export var itemlist : ItemList
@export var texture : Texture2D


func update_inventory(inventory: Inventory):
	itemlist.clear()
	for item in inventory.bag_items:
		var atlas = AtlasTexture.new()
		atlas.set_atlas(texture)
		atlas.set_region(tile_to_rect(Data.ITEMS[item.item_class]["Atlas"]))
		itemlist.add_item(item.item_class, atlas)



func tile_to_rect(tile: Vector2i)->Rect2i:
	return Rect2(tile*9, 8*Vector2i.ONE)
