extends Resource
class_name GameSave

@export_category("Dungeon")
@export var rooms: Array[Rect2i]
@export var connections: Array[Vector2i]
@export var depth : int
@export var astar_offset : Vector2i
@export var astar_map_contents: Array[bool]
@export var astar_map_dimensions : Vector2i

@export_category("Enemies")
@export var enemy_tile_loc : Array[Vector2i]
@export var enemy_health : Array[int]
@export var enemy_type : Array[String]

##todo: triggers
@export var trigger_managaer : TriggerManager

@export_category("Player")
@export var player_location : Vector2
@export var player_inventory : Inventory
@export var player_equipment: Equipment
@export var player_health : int
@export var player_max_health : int

func save_game(file_path : String)->void:
	print(ResourceSaver.save(self, file_path))

static func load_game(file_path: String)->GameSave:
	if ResourceLoader.exists(file_path):
		print("Found GameSave at file location.")
		return ResourceLoader.load(file_path, "GameSave")
	else: 
		print("Failed to find gamesave at file location.")
		return GameSave.new()
