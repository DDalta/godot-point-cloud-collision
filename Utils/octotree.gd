class_name OctoTree extends Resource

var _bottom_left_front: Vector3
var _top_right_back: Vector3
var _size: float
var _max_items: int
var _children_nodes: Array = []
var _point_data: Dictionary # empty nodes will store the data (if empty, we are in leaf node)
var _aabb: AABB

func _init(bottom_left_front: Vector3, top_right_back: Vector3, max_items: int = 1000) -> void:
	self._bottom_left_front = bottom_left_front
	self._top_right_back = top_right_back
	self._max_items = max_items
	
	self._aabb = AABB(self._bottom_left_front, self._top_right_back - self._bottom_left_front)

func insert(point: Vector3, data) -> bool:
	
	# check if valid position inside node
	if not self._aabb.has_point(point):
		return false
	
	# check if current node  has any children
	if not self._children_nodes.is_empty():
		# get node point is inside
		var node = self._children_nodes[_get_octant_index(point, (self._bottom_left_front + self._top_right_back) / 2)]
		
		if not node:
			return false
		
		return node.insert(point, data)
	else:
		# in leaf node
		
		# check if point already exists in node
		if self._point_data.has(point):
			return false
		
		self._point_data[point] = data
		
		if self._point_data.size() > self._max_items:
			# overfill; divde all data into new leaf nodes
			
			for i in range(8):
				if i&4: # right
					pass
				else:
					pass

				if i&2: # top
					pass
				else:
					pass

				if i&1: # front
					pass
				else:
					pass
		
	return true
func search(point: Vector3):
	pass

## Compute the index of this OctreeNode's _octant_nodes Array that would store the given position.
## the computed index aligns with the _octant_nodes Array order.
## https://github.com/daniel-mcclintock/Octree.gd
static func _get_octant_index(point: Vector3, center: Vector3) -> int:
	var oct = 0

	if point.x >= center.x:
		oct |= 4

	if point.y >= center.y:
		oct |= 2

	if point.z >= center.z:
		oct |= 1

	return oct
