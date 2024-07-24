extends Trigger
class_name Stair

@warning_ignore("shadowed_variable")
func _init(map_location: Vector2i, index: int):
	super.set_trigger(map_location, index, "Stair")

func activate(entity = null):
	if !entity: return
	super.delete_trigger()
