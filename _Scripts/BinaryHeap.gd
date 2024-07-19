extends RefCounted
class_name BinaryHeap
## timmygobbles
## I just coppied the implementation at:
## https://runestone.academy/ns/books/published/pythonds/Trees/BinaryHeapImplementation.html

var heap : Array = [0]

func _init(alist : Array = []):
	if alist:
		buildHeap(alist)

func insert(val):
	heap.append(val)
	heap[0] += 1
	percUp()

func percUp():
	var i = heap[0]
	while i /2 > 0:
		if heap[i] < heap[i/2]:
			var tmp = heap[i/2]
			heap[i/2] = heap[i]
			heap[i] = tmp
		i /= 2

func percDown(i : int):
	while i * 2 <= heap[0]:
		var mc = minChild(i)
		if heap[i] > heap[mc]:
			var tmp = heap[mc]
			heap[mc] = heap[i]
			heap[i] = tmp
		i = mc

func minChild(i: int):
	if i * 2 + 1 > heap[0]: return i * 2
	else:
		if heap[i*2] < heap[i*2 +1] : return i*2
		else: return i *2 +1

func delMin():
	if heap[0] == 0:
		print("Warning, delMin() called on empty BinaryHeap: ", self)
		return
	var minval = heap[1]
	heap[1] = heap[heap[0]]
	heap[0] -= 1
	heap.pop_back()
	percDown(1)
	return minval

func buildHeap(alist : Array):
	heap.resize(1)
	heap[0] = alist.size()
	heap.append_array(alist.duplicate())
	var i = heap[0]/2
	while i > 0:
		percDown(i)
		i -= 1

func size(): return heap[0]

func getMin(): return heap[1]
