extends RefCounted
class_name AStarPath
## timmygobbles
## source: http://theory.stanford.edu/~amitp/GameProgramming/ImplementationNotes.html

var map: MatrixB

func _init(new_map = MatrixB.new(1,1)):
	map = new_map

func heuristic(next : Vector2i, goal : Vector2i)-> int:
	return absi(next.x - goal.x) + absi(next.y - goal.y)

func a_star_search(start : Vector2i, goal: Vector2i, max_search : int = 0):
	
	var frontier = BinaryHeap.new()
	frontier.insert(Vector3(0.0, start.x, start.y))
	var came_from = {} # Dictionary{Vector2i : Vector2i}
	var cost_so_far = {} #Dictionary{Vector2i : int}
	came_from[start] = []
	cost_so_far[start] = 0
	
	while frontier.size() > 0:
		var tmp = frontier.delMin()
		var current = Vector2i(tmp.y, tmp.z)
		
		if current == goal: break
		
		for next in MatrixB.get_vnn_vec(current):
			if next.y < 0 or next.y >= map.num_rows or next.x < 0 or next.x >= map.num_cols: continue
			if !map.get_from_v(next): continue
			
			
			var new_cost = cost_so_far[current] + 1
			if max_search: if new_cost > max_search: break
			
			if new_cost < cost_so_far.get(next, INF):
				cost_so_far[next] = new_cost
				var priority = new_cost + heuristic(next, goal)
				frontier.insert(Vector3(priority, next.x, next.y))
				came_from[next] = current
	
	var path : Array[Vector2i] = [] 
	if !came_from.has(goal): return path
	
	var step = goal
	path = [step]
	
	while step != start:
		step = came_from[step]
		path.append(step)
		
	path.reverse() #since we track the goal backwards to the start
	
	return path
