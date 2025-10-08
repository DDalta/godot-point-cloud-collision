class_name RTreeNode extends Resource

var _children_nodes: Array = []
var _parent: RTreeNode = null
var _aabb: AABB = AABB()
var _point_data: Dictionary
var _max_items: int

func _init(max_items = 32):
	self._max_items = max_items

## Tree is travered recursively from the root node.
## At each step, all children are examined and a candidate is chosen using a heutrisitc
## The search continues until a leaf node is reached
## If leaf node is full, a split must be made before inserting
## A heurisitc is employed to split the node into two
func insert(point: Vector3, data: Variant):
	var leaf_node: RTreeNode = self._choose_leaf(point)
	leaf_node._update_data(point, data)
	if leaf_node._point_data.size() > leaf_node._max_items:
		# overflowing, split node
		var new_node = leaf_node._quadratic_split()
		_adjust_tree(leaf_node, new_node)
	else:
		_adjust_tree(leaf_node, null)

## "Searches for the pair of rectangles that is the worst combination to have in the same node,
## and puts them as initial objects into the two new groups. It then searches for the entry
## which has the strongest preference for one of the groups (in terms of area increase) and assigns
## the object to this group until all objects are assigned" (https://en.wikipedia.org/wiki/R-tree)
func _quadratic_split():
	var new_node = RTreeNode.new(self._max_items)
	var temp_data = self._point_data.duplicate()
	self._point_data.clear()
	self._aabb = AABB()
	
	var worse_combination = _get_worse_combination(temp_data.keys())
	
	self._update_data(worse_combination[0], temp_data.get(worse_combination[0]))
	new_node._update_data(worse_combination[1], temp_data.get(worse_combination[1]))

	temp_data.erase(worse_combination[0])
	temp_data.erase(worse_combination[1])

	for point in temp_data:
		var node_enlarged = self.get_aabb().expand(point)
		var new_node_enlarged = new_node.get_aabb().expand(point)
		
		var node_enlargement_diff = node_enlarged.get_volume() - self.get_aabb().get_volume()
		var new_node_enlargement_diff = new_node_enlarged.get_volume() - new_node.get_aabb().get_volume()
		
		if node_enlargement_diff == new_node_enlargement_diff:
			# if both enlargements are equal, choose the group with the smallest volume
			if node_enlarged.get_volume() < new_node_enlarged.get_volume():
				self._update_data(point, temp_data.get(point))
			else:
				new_node._update_data(point, temp_data.get(point))
		else:
			# choose the group that will have the smallest enlargement
			if node_enlargement_diff < new_node_enlargement_diff:
				self._update_data(point, temp_data.get(point))
			else:
				new_node._update_data(point, temp_data.get(point))
	
	return new_node

## splits a non-leaf node based the volume of its children
## same thing as _quadratic_split but using area instead of points
func _split_parent():
	var new_node: RTreeNode = RTreeNode.new(self._max_items)
	var temp_children: Array = self._children_nodes.duplicate()
	self.clear_data()
	
	var worse_combination = _get_worse_node_combination(temp_children)
	
	self._children_nodes.append(worse_combination[0])
	worse_combination[0]._parent = self
	self._aabb = self.get_aabb().merge(worse_combination[0].get_aabb())

	new_node._children_nodes.append(worse_combination[1])
	worse_combination[1]._parent = new_node
	new_node._aabb = new_node.get_aabb().merge(worse_combination[1].get_aabb())
	
	temp_children.erase(worse_combination[0])
	temp_children.erase(worse_combination[1])
	
	for child: RTreeNode in temp_children:
		var node_enlarged = self.get_aabb().merge(child.get_aabb())
		var new_node_enlarged = new_node.get_aabb().merge(child.get_aabb())
		
		var node_enlargement_diff = node_enlarged.get_volume() - self.get_aabb().get_volume()
		var new_node_enlargement_diff = new_node_enlarged.get_volume() - new_node.get_aabb().get_volume()
		
		if node_enlargement_diff == new_node_enlargement_diff:
			# if both enlargements are equal, choose the group with the smallest volume
			if node_enlarged.get_volume() < new_node_enlarged.get_volume():
				self._children_nodes.append(child)
				child._parent = self
				self._aabb = node_enlarged
			else:
				new_node._children_nodes.append(child)
				child._parent = new_node
				new_node._aabb = new_node_enlarged
		else:
			# choose the group that will have the smallest enlargement
			if node_enlargement_diff < new_node_enlargement_diff:
				self._children_nodes.append(child)
				child._parent = self
				self._aabb = node_enlarged
			else:
				new_node._children_nodes.append(child)
				child._parent = new_node
				new_node._aabb = new_node_enlarged
	return new_node

func search(point: Vector2):
	pass

func get_aabb() -> AABB:
	return self._aabb

## Clear all data from tree
func clear() -> void:
	if not self._children_nodes.is_empty():
		for node in self._children_nodes:
			node.clear()
		self.clear_data()
	else:
		self.clear_data()

func clear_data():
	self._children_nodes.clear()
	self._point_data.clear()
	self._aabb = AABB()

func _update_data(point: Vector3, data: Variant) -> void:
	self._point_data[point] = data
	if self._aabb: self._aabb = AABB(self._aabb.expand(point))
	else: self._aabb = AABB(point, Vector3.ZERO)

func _choose_leaf(point) -> RTreeNode:
	if self._children_nodes.is_empty(): return self
	var node: RTreeNode = _choose_least_area_enlargement(self._children_nodes, point)
	return node._choose_leaf(point)

func _update_aabb() -> void:
	var new_aabb: AABB = AABB()
	for child: RTreeNode in self._children_nodes:
		new_aabb = new_aabb.merge(child._aabb)
	self._aabb = new_aabb

func copy() -> RTreeNode:
	var new_node = RTreeNode.new(self._max_items)
	if self._children_nodes: new_node._children_nodes = self._children_nodes.duplicate()
	if self._point_data: new_node._point_data = self._point_data.duplicate()
	if self._aabb: new_node._aabb = self._aabb
	if self._parent: new_node._parent = self._parent
	return new_node

static func _adjust_tree(node: RTreeNode, new_node: RTreeNode):
	# if we are at root and there is a newnode, update the root
	if node._parent == null:
		if new_node != null:
			# make a new node and copy everything from node
			# assign node_copy and new_node to node's children and make their parent the node
			var node_copy: RTreeNode = node.copy()
			node_copy._max_items = node._max_items
			node.clear_data()
			node._children_nodes.append_array([node_copy, new_node])
			node._aabb = node_copy._aabb.merge(new_node._aabb)
			node_copy._parent = node
			new_node._parent = node
		return
	var parent: RTreeNode = node._parent
	if new_node:
		new_node._parent = parent
		parent._children_nodes.append(new_node)
	parent._update_aabb()
	
	# if number of childnodes have exceeded max_items
	if parent._children_nodes.size() > parent._max_items:
		# split the parent
		var new_parent = parent._split_parent()
		_adjust_tree(parent, new_parent)
	else:
		_adjust_tree(parent, null)

static func _get_worse_combination(points: Array):
	var worse_combination = [Vector3.ZERO, Vector3.ZERO]
	var worse_distance: float = -1
	for i in range(points.size()):
		for j in range(i + 1, points.size()):
			var distance = points[i].distance_to(points[j])
			if distance > worse_distance:
				worse_combination = [points[i], points[j]]
				worse_distance = distance
	return worse_combination

static func _get_worse_node_combination(nodes: Array):
	var worse_combination = [].resize(2)
	var worse_wasted_volume: float = -INF
	for i in range(nodes.size()):
		for j in range(i + 1, nodes.size()):
			var aabb1 = nodes[i].get_aabb()
			var aabb2 = nodes[j].get_aabb()
			var wasted_space = aabb1.merge(aabb2).get_volume() - (aabb1.get_volume() + aabb2.get_volume())
			if wasted_space > worse_wasted_volume:
				worse_combination = [nodes[i], nodes[j]]
				worse_wasted_volume = wasted_space
	return worse_combination

## POSSIBLE TODO: handle the case when the difference between volumes is equal
## Choose the node that enlarges the least when inserting a point
static func _choose_least_area_enlargement(nodes: Array, point: Vector3):
	var min_idx: int = 0
	var min_vol_diff: float = INF
	for i in range(nodes.size()):
		var volume: float = nodes[i].get_aabb().get_volume()
		var enlarged_aabb: AABB = nodes[i].get_aabb().expand(point)
		if enlarged_aabb.get_volume() - volume < min_vol_diff:
			min_idx = i
			min_vol_diff = enlarged_aabb.get_volume() - volume
	return nodes[min_idx]

static func print_rtree(node: RTreeNode, indentation="	"):
	if node._parent == null:
		print("ROOT NODE")
	if not node._children_nodes.is_empty():
		for i in range(node._children_nodes.size()):
			print("%s Child %d" % [indentation, i])
			var new_indentation = indentation + "	"
			print_rtree(node._children_nodes[i], new_indentation)
	else:
		print("%s Storing %d points" % [indentation, node._point_data.size()])
		for point in node._point_data:
			print("%s%v" % [indentation, point])
