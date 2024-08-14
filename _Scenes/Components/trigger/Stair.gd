extends Trigger
class_name Stair

@warning_ignore("shadowed_variable")
func _init(map_location: Vector2i = Vector2i.ZERO, index: int = 0)->void:
	if map_location or index:
		super.set_trigger(map_location, index, "Stair")

func activate(entity = null):
	if !entity: return
	super.delete_trigger()
