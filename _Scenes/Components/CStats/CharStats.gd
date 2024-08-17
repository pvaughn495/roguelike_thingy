extends Resource
class_name CharacterStats

var BASE_ATK = 0
var BASE_ARM = 0
var BASE_RES = 0

var cur_stats_dict : Dictionary

var atk:int
var arm:int
var res:int

func update_stats(stat_dict: Dictionary):
	if !stat_dict: stat_dict = cur_stats_dict
	else: cur_stats_dict = stat_dict
	atk = stat_dict.get("Atk", 0) + BASE_ATK
	arm = stat_dict.get("Arm", 0) + BASE_ARM
	res = stat_dict.get("Res", 0) + BASE_RES
	print("stats.update_stats, atk: ", atk, ", arm: ", arm, ", res: ", res)

func stats_reset()->void:
	cur_stats_dict = {}
	BASE_ATK = 0
	BASE_RES = 0
	BASE_ARM = 0
	atk = 0
	arm = 0
	res = 0

func process_level(level: int)->void:
	BASE_ATK = (level + 3) / 4
	BASE_ARM = level / 4
	BASE_RES = (level + 1) / 4
	update_stats({})
