@tool
extends Node3D

const WIREFRAME = preload("res://Shader/wireframe.tres")
const POINT_CLOUD = preload("res://Scenes/point_cloud.tscn")
@onready var point_cloud_mesh: MeshInstance3D = $PointCloud2
@onready var csg_box_3d: CSGBox3D = $CSGBox3D

@export var max_size: Vector3 = Vector3(10, 10, 10)
@export var enable_draw_octotree: bool = false
@export var point_count: int = 50
@export_tool_button("Regenerate Points") var gen_points_action = generate_points

var head: OctoTree
var collision_nodes: Array

func _ready() -> void:
	head = OctoTree.new(Vector3(0, 0, 0), Vector3(10, 10, 10), 5)
	generate_points()

func _process(delta: float) -> void:
	collision_nodes = head.check_aabb(AABB(csg_box_3d.global_position - (csg_box_3d.size / 2), csg_box_3d.size))
	var a = DebugDraw3D.new_scoped_config().set_thickness(0.02)
	if enable_draw_octotree:
		draw_octotree(head, Color.RED)

func generate_points():
	head.clear()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_POINTS)
	
	var count := 0
	for i in range(point_count):
		var point = Vector3(randf_range(0.0, 10.0), randf_range(0.0, 10.0), randf_range(0.0, 10.0))
		if head.insert(point, ""):
			st.set_color(Color.RED)
			st.add_vertex(point)
			count += 1
	print("%d Successful Inserts" % count)
	st.commit(mesh)
	point_cloud_mesh.mesh = mesh

func draw_octotree(node: OctoTree, color: Color, expand: float = 1.0) -> void:
	#DebugDraw3D.draw_box(node._bottom_left_front, Quaternion.IDENTITY, node._size * expand, color)
	DebugDraw3D.draw_aabb(node._aabb, color)
	for i in node._children_nodes:
		if i in collision_nodes: draw_octotree(i, Color.GREEN, 1.01)
		else: draw_octotree(i, Color.BLUE)
	return
