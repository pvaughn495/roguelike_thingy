extends RefCounted
class_name AttackPatterns

static func get_attacked_tiles(start: Vector2i, direction: Vector2i, dir_type : String,
	atk_range: int)->Array[Vector2i]:
	
	var attack_tiles : Array[Vector2i] = []
	
	match dir_type:
		"Orthogonal": 
			for i in atk_range:
				attack_tiles.append(start + (i+1)*direction)
			
		"Diagonal" : 
			var orthogonal : Vector2i
			if abs(direction.x) > 0: orthogonal = Vector2i.DOWN
			else: orthogonal = Vector2i.RIGHT
				
			for i in range(1, atk_range + 1):
				for j in range(-i, i+1):
					attack_tiles.append(start + j*orthogonal + i*direction)
	
	return attack_tiles
