extends RefCounted
class_name Trigger

var map_location : Vector2i
var armed : bool
var index : int
var type : StringName


signal call_trigger
signal del_trigger

func connect_call_trigger(_entity):
	pass

func activate(_entity = null):
	call_trigger.emit()
	pass

@warning_ignore("shadowed_variable")
func set_trigger(map_location : Vector2i, index : int, type : StringName)->void:
	self.map_location = map_location
	self.index = index
	self.type = type
	arm()

func arm():
	armed = true

func disarm():
	armed = false

@warning_ignore("shadowed_variable")
func set_index(index: int):
	self.index = index

func get_index()->int:
	return index

func delete_trigger():
	disarm()
	del_trigger.emit(index)


@warning_ignore("shadowed_variable")
static func new_trigger(args : Dictionary, map_location: Vector2i, index : int)->Trigger:
	var trig : Trigger
	match args["Type"]:
		"Trap": 
			trig = Trap.new(map_location, args["Oneshot"], args["Damage"], index)
		"Chest": pass
		"Stair": pass
		_: trig = null
	
	return trig




