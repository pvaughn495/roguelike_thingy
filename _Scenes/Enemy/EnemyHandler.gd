extends RefCounted
class_name EnemyHandler

const ATLAS_SCALE = 9
const ATLAS_SIZE = Vector2i(8,8)

var enemies_node : Node2D
var enemies : Array[Enemy]
var enemy_tiles : Array[Vector2i]
var astar = AStarPath

var texture : Texture2D = preload("res://Art/kenney_micro-roguelike/Tilemap/colored_tilemap.png")

func add_enemy(new_enemy: Enemy):
	new_enemy.index = enemies.size()
	enemies.append(new_enemy)

func delete_enemy(enemy: Enemy):
	var enemy_idx = enemy.index
	enemies.remove_at(enemy_idx)
	enemy_tiles.remove_at(enemy_idx)
	for i in range(enemy_idx, enemies.size()):
		enemies[i].index = i

func get_enemy_at_tile(tile: Vector2i)->int:
	return enemy_tiles.find(tile)











