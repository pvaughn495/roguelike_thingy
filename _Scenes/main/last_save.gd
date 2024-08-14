extends Resource
class_name LastSave

const base_file_name := "user://lastsavename.tres"

@export var last_save : int

func save_last(file_num : int)->void:
	last_save = file_num
	ResourceSaver.save(self, base_file_name)

static func load_last()->int:
	if ResourceLoader.exists(base_file_name):
		var lastsave : LastSave
		lastsave = ResourceLoader.load(base_file_name, "LastSave")
		return lastsave.last_save
	else: return 0
