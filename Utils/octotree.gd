class_name OctoTree extends Resource

var _bottom_left_front: Vector3
var _top_right_back: Vector3
var _size: Vector3
var _center: Vector3
var _max_items: int
var _children_nodes: Array = []
var _point_data: Dictionary # empty nodes will store the data (if empty, we are in leaf node)
var _aabb: AABB

func _init(bottom_left_front: Vector3, top_right_back: Vector3, max_items: int = 1000) -> void:
	self._bottom_left_front = bottom_left_front
	self._top_right_back = top_right_back
	self._max_items = max_items
	
	self._size = self._top_right_back - self._bottom_left_front
	
	#print(self._bottom_left_front, self._top_right_back, self._size, self._max_items)
	
	self._center = (self._bottom_left_front + self._top_right_back) * 0.5
	
	self._aabb = AABB(self._bottom_left_front, self._size)

func insert(point: Vector3, data) -> bool:
	#print("Inserting %v" % point)
	# check if valid position inside node
	if not self._aabb.has_point(point):
		print("%v does not fit inside %v by %v" % [point, self._aabb.position, self._aabb.position+self._aabb.size])
		return false
	
	# check if current node  has any children
	if not self._children_nodes.is_empty():
		# get node point is inside
		var node = self._children_nodes[_get_octant_index(point, self._center)]
		
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
			# overfill; divide all data into new leaf nodes
			
			# create children (## https://github.com/daniel-mcclintock/Octree.gd)
			for i in range(8):
				var new_bottom_left_front := self._bottom_left_front
				var new_top_right_back := self._top_right_back
				
				if i&4: # front
					new_top_right_back.x -= self._size.x * 0.5
				else:
					new_bottom_left_front.x += self._size.x * 0.5

				if i&2: # top
					new_bottom_left_front.y += self._size.y * 0.5
				else:
					new_top_right_back.y -= self._size.y * 0.5

				if i&1: # right
					new_bottom_left_front.z += self._size.z * 0.5
				else:
					new_top_right_back.z -= self._size.z * 0.5
				
				self._children_nodes.append(OctoTree.new(new_bottom_left_front, new_top_right_back, self._max_items))
				
			# divide the data into the generated child nodes
			for key in self._point_data.keys():
				var node = self._children_nodes[_get_octant_index(key, self._center)]
				node._point_data[key] = self._point_data[key]
			
			self._point_data.clear()
	
	return true

func search(point: Vector3):
	if self._point_data.has(point):
		return self._point_data[point]
	
	if not self._children_nodes.is_empty():
		var node = self._children_nodes[_get_octant_index(point, self._center)]
		return node.search(point)
	
	return null

## Compute the index of this OctreeNode's _octant_nodes Array that would store the given position.
## the computed index aligns with the _octant_nodes Array order.
## https://github.com/daniel-mcclintock/Octree.gd
static func _get_octant_index(point: Vector3, center: Vector3) -> int:
	var oct = 0

	if point.x <= center.x: # front
		oct |= 4

	if point.y >= center.y: # top
		oct |= 2

	if point.z >= center.z: # right
		oct |= 1

	return oct
