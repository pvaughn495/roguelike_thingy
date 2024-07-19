extends RefCounted
class_name PoissonDiskLoose
## timmygobbles
## generates a sample of int-points that is loosely centered at (0,0), using a similar algorithm to
## poisson disk sampling. Instead of filling a region using poisson disk sampling, generate_sample
## uses a binary heap as a priority queue to decide which sample points to attempt to generate new points.
## The method is complete when n points are generated.
## The disk uses euclidean distance by default, but l-1 and l-inf norms can be used alternatively
## for square or diamond shaped disks instead. 



const NEIGHBORS = [Vector2i(-1,-1), Vector2i.UP, Vector2i(1,-1), Vector2i.RIGHT,
	Vector2i(1,1), Vector2i.DOWN, Vector2i(-1,1), Vector2i.LEFT]

func generate_sample(min_dist : float, num_samples : int, norm: int = 2) -> Array[Vector2i]:
	
	var sample_points : Array[Vector2i] = []
	var queue = BinaryHeap.new()
	var grid : Array[Vector2i] = []
	var grid_pointers : Array[int] = []
	var dist_fnc : Callable
	
	var grid_size: float
	match norm:
		-1:
			grid_size = float(min_dist)
			dist_fnc = Norms.vector2i_linf
		1:
			grid_size = min_dist/2.0
			dist_fnc = Norms.vector2i_l1
		2:
			grid_size = min_dist/sqrt(2.0)
			dist_fnc = func (v:Vector2i)->float: return v.length()
	
	var vec_to_grid = func (v : Vector2i) ->Vector2i:
		return Vector2i(floor(v/grid_size))
	
	var insert_grid = func (new : Vector2i, new_index : int) -> bool:
		var grid_index = grid.bsearch(new)
		if grid_index == grid.size():
			grid.append(new)
			grid_pointers.append(new_index)
			return true
		if grid[grid_index] != new:
			grid.insert(grid_index, new)
			grid_pointers.insert(grid_index, new_index)
			return true
		return false
	
	var get_pointer_from_grid = func (grid_vec: Vector2i)-> int:
		var grid_index = grid.bsearch(grid_vec)
		if grid.size() == grid_index:
			return -1
		if grid[grid_index] == grid_vec: return grid_pointers[grid_index]
		return -1
	
	sample_points.append(Vector2i.ZERO)
	insert_grid.call(sample_points[0], 0)
	queue.insert([0, 0])
	num_samples -= 1
	
	while(num_samples > 0):
		var center = sample_points[queue.getMin()[1]]
		queue.heap[1][0] += 1
		if queue.heap[1][0] > queue.heap[1][1] + 10:
			queue.delMin()
		queue.percDown(1)
		var new = random_disk_point(center, min_dist, norm)
		var new_grid = vec_to_grid.call(new)
		if get_pointer_from_grid.call(new_grid) >= 0:#already a point in the space
			continue
		var good = true
		for i in range(-2,3):
			for j in range(-2,3):
				if i == 0 and j == 0: continue
				var neighbor_index = get_pointer_from_grid.call(new_grid + Vector2i(i,j))
				if neighbor_index == -1: continue
				if dist_fnc.call(new - sample_points[neighbor_index]) < min_dist:
					good = false
					break
			if !good: break
		if !good:
			continue
		queue.insert([sample_points.size(), sample_points.size()])
		insert_grid.call(new_grid, sample_points.size())
		sample_points.append(new)
		num_samples -= 1
	return sample_points

func random_disk_point(center : Vector2i, min_dist : float, norm : int = 2)->Vector2i:
	#norms: -1: inf, 1: L1, 2: L2 or pythag
	var theta : float
	if norm == -1:
		theta = randf_range(-PI/4.0,7.0*PI/4.0)
	else: theta = randf_range(0.0, 2.0*PI)
	var r : float = randf_range(min_dist, min_dist*1.5)
	
	var del : Vector2i
	match norm:
		-1:
			if theta < PI/4.0: del = Vector2i(r, r*tan(theta))
			elif theta < 3.0*PI/4.0: del = Vector2i(r/tan(theta), r)
			elif theta < 5.0*PI/4.0: del = Vector2i(-r, -r*tan(theta))
			else: del = Vector2i(-r/tan(theta), -r)
		1:
			var a : float
			var b : float
			if theta < PI/2.0:
				a = cos(theta)
				b = sin(theta)
				del = Vector2i(r*a/(a+b), r*b/(a+b))
			elif theta < PI:
				a = cos(PI - theta)
				b = sin(PI - theta)
				del = Vector2i(-r*a/(a+b), r*b/(a+b))
			elif theta < 1.5*PI:
				a = cos(theta - PI)
				b = sin(theta - PI)
				del = Vector2i(-r*a/(a+b), -r*b/(a+b))
			else:
				a = cos(2.0*PI - theta)
				b = sin(2.0*PI - theta)
				del = Vector2i(r*b/(a+b), -r*a/(a+b))
		2: del = Vector2i(r*cos(theta), r*sin(theta))
	
	return center + del
