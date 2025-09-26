extends Node3D

const WIREFRAME = preload("res://Shader/wireframe.tres")
const POINT_CLOUD = preload("res://Scenes/point_cloud.tscn")

@onready var csg_box_3d: CSGBox3D = $CSGBox3D

var head: OctoTree


func _ready() -> void:
	head = OctoTree.new(Vector3(0, 0, 0), Vector3(10, 10, 10), 4)
	#print(head._aabb.position)
	#print(head._aabb.size)
	
	var instance = POINT_CLOUD.instantiate()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_POINTS)
	#instance.mesh = PlyFile.generate_mesh(pointcloud)
	
	
	var count := 0
	for i in range(80):
		var point = Vector3(randf_range(0.0, 10.0), randf_range(0.0, 10.0), randf_range(0.0, 10.0))
		if head.insert(point, ""):
			st.set_color(Color.RED)
			st.add_vertex(point)
			count += 1
	print("%d Successful Inserts" % count)
	st.commit(mesh)
	instance.mesh = mesh
	add_child(instance)
	
	
	
func _process(delta: float) -> void:
	var a = DebugDraw3D.new_scoped_config().set_thickness(0.02)
	draw_octotree(head, Color.RED)
	# DebugDraw3D.draw_box(pos, Quaternion.IDENTITY, size, Color.RED)
	
func draw_octotree(node: OctoTree, color: Color) -> void:
	DebugDraw3D.draw_box(node._bottom_left_front, Quaternion.IDENTITY, node._size, color)
	for i in node._children_nodes:
		draw_octotree(i, Color.BLUE)
	return
