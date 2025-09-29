class_name RTree extends Resource

var _max_items: int
var _children_nodes: Array = []
var _aabb: AABB
var _point_data: Dictionary

func _init(point_data = {}, max_items = 100):
	self._point_data = point_data
	self._max_items = max_items
	


## Tree is travered recursively from the root node.
## At each step, all children are examined and a candidate is chosen using a heutrisitc
## The search continues until a leaf node is reached
## If leaf node is full, a split must be made before inserting
## A heurisitc is employed to split the node into two
func insert(point: Vector3, data):
	if not self._children_nodes.is_empty():
		# choose which subnode is best to insert and recurse
		var node = _choose_least_area_enlargement(self._children_nodes, point)
		return node.insert(point)
	else:
		# leaf node
		self._point_data[point] = data
		self._aabb = AABB(self._aabb.expand(point))
		if self._point_data.size() > self._max_items:
			# overflowing, split node
			var split_node = self.quadratic_split()

## "Searches for the pair of rectangles that is the worst combination to have in the same node,
## and puts them as initial objects into the two new groups. It then searches for the entry
## which has the strongest preference for one of the groups (in terms of area increase) and assigns
## the object to this group until all objects are assigned" (https://en.wikipedia.org/wiki/R-tree)
func quadratic_split():
	var worse_combination = _get_worse_combination(self._point_data.keys())
	
	var group1 = {worse_combination[0]: self._point_data.get(worse_combination[0])}
	var group2 = {worse_combination[1]: self._point_data.get(worse_combination[1])}
	var group1_aabb = AABB(worse_combination[0], Vector3.ZERO)
	var group2_aabb = AABB(worse_combination[1], Vector3.ZERO)
	
	self._point_data.erase(worse_combination[0])
	self._point_data.erase(worse_combination[1])
	
	for point in self._point_data:
		var group1_enlargement = group1_aabb.expand(point)
		var group2_enlargement = group2_aabb.expand(point)
		
		var group1_enlargement_volume = group1_enlargement.get_volume()
		var group2_enlargement_volume = group2_enlargement.get_volume()
		
		if group1_enlargement_volume == group2_enlargement_volume:
			# if both enlargements are equal, choose the group with the smallest volume
			if group1_aabb.get_volume() < group2_aabb.get_volume():
				group1[point] = self._point_data.get(point)
				group1_aabb = group1_enlargement
			else:
				group2[point] = self._point_data.get(point)
				group2_aabb = group2_enlargement
		else:
			# choose the group that will have the smallest enlargement
			if group1_enlargement_volume < group2_enlargement_volume:
				group1[point] = self._point_data.get(point)
				group1_aabb = group1_enlargement
			else:
				group2[point] = self._point_data.get(point)
				group2_aabb = group2_enlargement

	self._point_data.clear()

func clear():
	pass

func search(point: Vector2):
	pass

func get_aabb() -> AABB:
	return self._aabb

static func _get_worse_combination(points: Array[Vector3]):
	var worse_combination = [Vector3.ZERO, Vector3.ZERO]
	var worse_distance: float = -1
	for i in range(points.size()):
		for j in range(i + 1, points.size()):
			var distance = points[i].distance_to(points[j])
			if distance > worse_distance:
				worse_combination = [points[i], points[j]]
				worse_distance = distance
	return worse_combination

## POSSIBLE TODO: handle the case when the difference between volumes is equal
## Choose the node that enlarges the least when inserting a point
static func _choose_least_area_enlargement(nodes: Array, point: Vector3):
	var min_idx: int = INF
	for i in range(nodes.size()):
		var volume: float = nodes[i].get_aabb().get_volume()
		var enlarged_aabb: AABB = nodes[i].get_aabb().expand(point)
		if enlarged_aabb.get_volume() - volume < min_idx:
			min_idx = i
	return nodes[min_idx]
