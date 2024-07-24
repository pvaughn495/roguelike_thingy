extends RefCounted
class_name MatrixI

const NEIGHBORS_I = [-1, -1, -1, 0, 1, 1, 1, 0]
const NEIGHBORS_J = [-1, 0, 1, 1, 1, 0, -1 ,-1]

var num_rows : int = 1
var num_cols : int = 1

var contents : Array[int]

#m: number of rows, n: number of columns
#i: row index, j: column index

func _init(m : int = 1, n: int = 1, val : int = 0):
	num_rows = m
	num_cols = n
	for i in range(num_rows*num_cols):
		contents.append(val)

func ij_to_index(i :int, j:int) -> int:
	return i + j*num_rows

func index_to_ij(index : int) -> Vector2i:
	return Vector2i(index%num_rows, index/num_rows)

func index_to_xy(index : int) -> Vector2i:
	return Vector2i(index/num_rows, index%num_rows)

func get_from_ij(i:int, j:int) -> int:
	if i < 0 or i >= num_rows or j < 0 or j >= num_cols: return 0
	return contents[ij_to_index(i,j)]

func get_width() -> int: return num_cols

func get_height() -> int: return num_rows

func get_from_coord(coord : Vector2i) -> int:
	return get_from_ij(coord.y, coord.x)

func set_at_ij(i:int, j:int, val : int):
	if i < 0 or i >= num_rows or j < 0 or j >= num_cols: return
	contents[ij_to_index(i,j)] = val

func set_at_coord(coord : Vector2i, val : int):
	set_at_ij(coord.y, coord.x, val)

func get_neighbors_from_coord(coord: Vector2i)->Array[int]:
	var neighbors : Array[int] = []
	neighbors.resize(8)
	var n_i = 0
	var n_j = 0
	for k in 8:
		n_i = coord.y + NEIGHBORS_I[k]
		n_j = coord.x + NEIGHBORS_J[k]
		if n_i < 0 or n_j < 0 or n_i >= num_rows or n_j >= num_cols: neighbors[k] = NAN
		else: neighbors[k] = get_from_ij(n_i, n_j)
	return neighbors

func get_row(i:int) -> Array[int]:
	var row : Array[int] = []
	for j in range(num_cols):
		row.append(get_from_ij(i,j))
	return row

func set_row(i:int, row :Array[int]):
	for j in range(num_cols):
		set_at_ij(i,j,row[j])

func get_col(j:int) -> Array[int]:
	var col : Array[int]= []
	for i in range(num_rows):
		col.append(get_from_ij(i,j))
	return col

func set_col(j:int, col : Array[int]):
	for i in range(num_rows):
		set_at_ij(i,j,col[i])


func print_matrixi():
	for i in range(num_rows):
		print(get_row(i))

func _add(matrix:MatrixI):
	if num_cols != matrix.num_cols :
		print("Matrix dimension missmatch: num_cols ", num_cols,
		 " does not equal ", matrix.num_cols)
		return
	if num_rows != matrix.num_rows:
		print("Matrix dimension missmatch: num_rows ", num_rows, 
		" does not equal ", matrix.num_rows)
		return
	for index in range(num_rows*num_cols):
		contents[index] += matrix.contents[index]

func scaler_mult(a: float):
	for index in range(num_rows*num_cols):
		contents[index] = int(a * contents[index])

func duplicate() -> MatrixI:
	var matrix = MatrixI.new(num_rows, num_cols)
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

static func dot_prod(vec1 : Array[int], vec2: Array[int]) -> int:
	if vec1.size() != vec2.size():
		print("Vector dimension missmatch!")
		return NAN
	var prod : int = 0
	for index in range(vec1.size()):
		prod += vec1[index]*vec2[index]
	return prod

static func matrix_times_vec(A: MatrixI, x: Array[int]) -> Array[int]:
	var b : Array[int] = []
	if A.num_cols != x.size():
		print("Matrix dimension missmatch!")
	else:
		for i in range(A.num_rows):
			b.append(MatrixI.dot_prod(A.get_row(i), x))
	return b

static func matrix_mult(A : MatrixI, B : MatrixI) -> MatrixI:
	if A.num_cols != B.num_rows :
		print("Dimension missmatch!")
		return null
	var C = MatrixI.new(A.num_rows, B.num_cols)
	for i in range(C.num_rows):
		for j in range(C.num_cols):
			C.set_at_ij(i,j, MatrixI.dot_prod(A.get_row(i), B.get_col(j)))
	
	return C


