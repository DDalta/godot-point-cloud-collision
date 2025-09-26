extends Node3D

const WIREFRAME = preload("res://Shader/wireframe.gdshader")

func _ready() -> void:
	var head = OctoTree.new(Vector3(-5, -5, -5), Vector3(5, 5, 5))
	
	print(head._aabb.position)
	print(head._aabb.size)
	
	var inserts = [ head.insert(Vector3(1, 1, 1), "red"), 
				head.insert(Vector3(1, 2, 1), "bruh"),
				head.insert(Vector3(2, 1, 2), "green"),
				head.insert(Vector3(1, 1, 1), "black")]
				
	print(inserts)
	print(head.search(Vector3(1, 2, 1)))
	
	var bottom_left_front = Vector3(-5, -5, -5)
	var top_right_back = Vector3(5, 5, 5)
	var pos = (bottom_left_front + top_right_back) * 0.5
	var size = top_right_back - bottom_left_front
	
	var instance = MeshInstance3D.new()
	add_child(instance)
	instance.mesh = BoxMesh.new()
	instance.global_position = pos
	instance.scale = size
	instance.material_override = WIREFRAME
	
