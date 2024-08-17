extends Trigger
class_name Trap

var one_shot : bool
var damage : int

@warning_ignore("shadowed_variable")
func _init(map_location, one_shot, damage, index)->void:
	self.one_shot = one_shot
	self.damage = damage
	super.set_trigger(map_location, index, "Trap")

func activate(entity = null, val : int = 0)->void:
	if entity:
		entity.take_damage(damage)
		if one_shot:
			super.delete_trigger()
