extends RefCounted
class_name MatrixB

const NEIGHBORS_I = [-1, -1, -1, 0, 1, 1, 1, 0]
const NEIGHBORS_J = [-1, 0, 1, 1, 1, 0, -1 ,-1]

var num_rows : int = 1
var num_cols : int = 1

var contents : Array[bool]

#m: number of rows, n: number of columns
#i: row index, j: column index

func _init(m : int = 1, n: int = 1, val : bool = false):
	num_rows = m
	num_cols = n
	contents.resize(m*n)
	contents.fill(val)

func ij_to_index(i :int, j:int) -> int:
	return i + j*num_rows

func index_to_ij(index : int) -> Vector2i:
	return Vector2i(index%num_rows, index/num_rows)

func index_to_xy(index : int) -> Vector2i:
	return Vector2i(index/num_rows, index%num_rows)

func get_from_ij(i:int, j:int) -> bool:
	if i < 0 or i >= num_rows or j < 0 or j >= num_cols:
		print("Out of bounds error on ", self, " for get_from_ij, i =", i, " ROWS = ", num_rows, 
		"j = ", j, " COLS = ", num_cols)
		return false
	return contents[ij_to_index(i,j)]

func get_from_v(vec: Vector2i) -> bool:
	return get_from_ij(vec.y, vec.x)

func set_at_ij(i:int, j:int, val : bool):
	if i < 0 or i >= num_rows or j < 0 or j >= num_cols:
		print("Out of bounds error on ", self, " for set_at_ij, i =", i, " ROWS = ", num_rows, 
		"j = ", j, " COLS = ", num_cols)
		return
	contents[ij_to_index(i,j)] = val

func set_at_v(vec: Vector2i, val):
	set_at_ij(vec.y, vec.x, val)

func get_row(i:int) -> Array[bool]:
	var row : Array[bool] = []
	for j in range(num_cols):
		row.append(get_from_ij(i,j))
	return row

func set_row(i:int, row :Array[bool]):
	for j in range(num_cols):
		set_at_ij(i,j,row[j])

func get_col(j:int) -> Array[bool]:
	var col : Array[bool]= []
	for i in range(num_rows):
		col.append(get_from_ij(i,j))
	return col

func set_col(j:int, col : Array[bool]):
	for i in range(num_rows):
		set_at_ij(i,j,col[i])

func get_neighboring_vals(i : int, j : int, _wrapping : bool = true) -> Array[bool]:
	var neighbors : Array[bool] = []
	for index in 8:
		neighbors.append(get_from_ij(wrapi(NEIGHBORS_I[index] + i, 0, num_rows-1),
			wrapi(NEIGHBORS_J[index] + j, 0, num_cols-1)))
	#todo: implement not wrapping
	return neighbors

func get_neighboring_vec(vec : Vector2i) -> Array[Vector2i]:
	var neighbor_vecs : Array[Vector2i] = []
	
	for index in 8:
		neighbor_vecs.append(Vector2i(NEIGHBORS_J[index], NEIGHBORS_I[index] + vec))
	
	return neighbor_vecs

func print_matrixb():
	for i in range(num_rows):
		print(get_row(i))

func _and(matrix:MatrixB):
	if num_cols != matrix.num_cols :
		print("Matrix dimension missmatch: num_cols ", num_cols,
		 " does not equal ", matrix.num_cols)
		return
	if num_rows != matrix.num_rows:
		print("Matrix dimension missmatch: num_rows ", num_rows, 
		" does not equal ", matrix.num_rows)
		return
	for index in range(num_rows*num_cols):
		contents[index] = contents[index] and matrix.contents[index]

func duplicate() -> MatrixB:
	var matrix = MatrixB.new(num_rows, num_cols)
	matrix.contents = contents.duplicate()
	return matrix

func clear():
	contents.clear()
	num_rows = 0
	num_cols = 0

func resize(m: int, n: int):
	#does not preserve contents
	num_rows = m
	num_cols = n
	contents.clear()
	contents.resize(num_rows*num_cols)

#----------------------Static Funcs-----------------------------------------

static func get_vnn_vec(vec : Vector2i): return [Vector2i.RIGHT, Vector2i.UP, 
	Vector2i.LEFT, Vector2i.DOWN].map(func(a): return vec + a)

static func get_mn_vec(vec: Vector2i): return [Vector2i.RIGHT, Vector2i(1,-1),
	Vector2i.UP, Vector2i(-1,-1), Vector2i.LEFT, Vector2i(-1,1), Vector2i.DOWN,
	Vector2i(1,1)].map(func(a): return vec + a)
