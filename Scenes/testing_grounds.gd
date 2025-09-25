extends Node2D

func _ready() -> void:
	var head = OctoTree.new(Vector3(-5, -5, -5), Vector3(5, 5, 5))
	
	print(head._aabb.position)
	print(head._aabb.size)
