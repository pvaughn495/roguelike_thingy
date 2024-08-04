extends RefCounted
class_name CharacterStats

const BASE_ATK = 1
const BASE_ARM = 0


var atk:int
var arm:int

func update_stats(stat_dict: Dictionary):
	atk = stat_dict.get("Atk", 0) + BASE_ATK
	arm = stat_dict.get("Arm", 0) + BASE_ARM
	
