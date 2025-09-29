class_name RTree extends Resource

var _max_items: int
var _children_nodes: Array = []
var _aabb: AABB

func _init(max_items):
	self._max_items = max_items

func insert(point: Vector2) -> bool:
	pass
