extends RefCounted
class_name TriggerManager

var triggers : Array[Trigger]
var trigger_map_list : Array[Vector2i]
var tilemap : TileMap

@warning_ignore("shadowed_variable")
func _init(tilemap):
	triggers = []
	trigger_map_list = []
	self.tilemap = tilemap


func reset():
	triggers.resize(0)
	trigger_map_list.resize(0)


func get_trigger_from_map(map_location : Vector2i)->Trigger:
	var trigger_index = trigger_map_list.find(map_location)
	if trigger_index == -1: return null
	else: return triggers[trigger_index]


func add_trigger(map_location, type, args:={}):
	
	var new_trigger : Trigger
	
	match type:
		"Trap":
			tilemap.set_cell(1, map_location, 0, DungeonGenerator.DUN_DICT["Interior"]["Trap"]) 
			new_trigger = Trap.new(map_location, args["one_shot"], args["damage"], triggers.size())
		"Chest" : 
			tilemap.set_cell(1, map_location, 0, DungeonGenerator.DUN_DICT["Interior"]["Chest"])
			new_trigger = Chest.new(map_location, triggers.size())
		"Stair" :
			tilemap.set_cell(1, map_location, 0, DungeonGenerator.DUN_DICT["Interior"]["Stair_Down"]) 
			new_trigger = Stair.new(map_location, triggers.size())
		_: print("Error, ", self, " invalid trigger type used in add_trigger function.")
	
	if new_trigger:
		triggers.append(new_trigger)
		trigger_map_list.append(map_location)


func delete_trigger(index: int)->void:
	tilemap.erase_cell(1, trigger_map_list[index])
	triggers.remove_at(index)
	trigger_map_list.remove_at(index)
	for i in range(index, triggers.size()):
		triggers[i].index = i
