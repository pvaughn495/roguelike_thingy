extends RefCounted
class_name CharacterStats

const BASE_ATK = 1
const BASE_ARM = 0
const BASE_RES = 0


var atk:int
var arm:int
var res:int

func update_stats(stat_dict: Dictionary):
	atk = stat_dict.get("Atk", 0) + BASE_ATK
	arm = stat_dict.get("Arm", 0) + BASE_ARM
	res = stat_dict.get("Res", 0) + BASE_RES
	
