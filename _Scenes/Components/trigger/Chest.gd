extends Trigger
class_name Chest

@warning_ignore("shadowed_variable")
func _init(map_location, index):
	super.set_trigger(map_location, index, "Chest")

func activate(entity = null):
	if !entity: return
	super.delete_trigger()
