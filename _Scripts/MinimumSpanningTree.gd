extends RefCounted
class_name MinimumSpanningTree

static func prims_alg(vertices : PackedVector2Array, f = func(v): return v.length()) -> Array[Vector2i]:
	
	var num_verts = vertices.size()
	var nodes : Array = []
	
	nodes.resize(num_verts)
	for i in num_verts:
		nodes[i] = []
	
	var f_ij = func(i:int, j:int)->float:
		return f.call(vertices[i] - vertices[nodes[i][j]])
	
	var triangles = Geometry2D.triangulate_delaunay(vertices)
	
	for i in range(triangles.size()/3):
		if !nodes[triangles[3*i]].has(triangles[3*i+1]): nodes[triangles[3*i]].append(triangles[3*i+1])
		if !nodes[triangles[3*i]].has(triangles[3*i+2]): nodes[triangles[3*i]].append(triangles[3*i+2])
		
		if !nodes[triangles[3*i+1]].has(triangles[3*i]): nodes[triangles[3*i+1]].append(triangles[3*i])
		if !nodes[triangles[3*i+1]].has(triangles[3*i+2]): nodes[triangles[3*i+1]].append(triangles[3*i+2])
		
		if !nodes[triangles[3*i+2]].has(triangles[3*i]): nodes[triangles[3*i+2]].append(triangles[3*i])
		if !nodes[triangles[3*i+2]].has(triangles[3*i+1]): nodes[triangles[3*i+2]].append(triangles[3*i+1])

	triangles.clear()
	
	var mst_set : Array[bool] = []
	mst_set.resize(num_verts)
	for i in num_verts:
		mst_set[i] = false
	
	var node_fitness : Array[float] = []
	node_fitness.resize(num_verts)
	node_fitness.fill(INF)
	
	node_fitness[0] = 0.0
	var mst_edges : Array[Vector2i] = []
	
	for i in num_verts:
		var u = -1
		for j in num_verts: #find the index with the smallest val that isnt already in the graph
			if mst_set[j]: continue #if its already in the tree, ignore it
			if u == -1:
				u = j
				continue
			if node_fitness[j] < node_fitness[u]: u = j
		#add that index to the graph, and update the vals, and add the vec to edges
		mst_set[u] = true
		var v = -1
		for j in nodes[u].size():
			if mst_set[nodes[u][j]]:
				if v == -1: v = j
				elif f_ij.call(u, j) < f_ij.call(u, v): v = j
			else: node_fitness[nodes[u][j]] = min(node_fitness[nodes[u][j]], f_ij.call(u, j))
		if i == 0: continue
		mst_edges.append(Vector2i(u,nodes[u][v]))
		
	return mst_edges
