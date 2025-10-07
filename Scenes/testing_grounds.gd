@tool
extends Node3D

const WIREFRAME = preload("res://Shader/wireframe.tres")
const POINT_CLOUD = preload("res://Scenes/point_cloud.tscn")
@onready var point_cloud_mesh: MeshInstance3D = $PointCloud2
@onready var csg_box_3d: CSGBox3D = $CSGBox3D

@export var max_size: Vector3 = Vector3(10, 10, 10)
@export var enable_draw_octotree: bool = false
@export var point_count: int = 150
@export_tool_button("Regenerate Points") var gen_points_action = generate_points

var rtree: RTreeNode
var collision_nodes: Array

func _ready() -> void:
	rtree = RTreeNode.new(3)
	generate_points()

func _process(delta: float) -> void:
	var a = DebugDraw3D.new_scoped_config().set_thickness(0.02)
	draw_rtree(rtree)

func generate_points():
	rtree.clear()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_POINTS)
	
	for i in range(point_count):
		var point = Vector3(randf_range(0, 10), randf_range(0, 10), randf_range(0, 10))
		rtree.insert(point, "")
		st.set_color(Color.RED)
		st.add_vertex(point)
	st.commit(mesh)
	point_cloud_mesh.mesh = mesh
	RTreeNode.print_rtree(rtree)

func draw_rtree(node: RTreeNode):
	if node._parent == null:
		DebugDraw3D.draw_aabb(node.get_aabb(), Color.RED)
	if not node._children_nodes.is_empty():
		DebugDraw3D.draw_aabb(node.get_aabb(), Color.BLUE)
		for i in range(node._children_nodes.size()):
			draw_rtree(node._children_nodes[i])
	else:
		DebugDraw3D.draw_aabb(node.get_aabb().grow(0.01), Color.GREEN)
		for point in node._point_data:
			DebugDraw3D.draw_text(point + Vector3(0, 0.2, 0), "%v" % point)
 

func draw_octotree(node: OctoTree, color: Color, expand: float = 1.0) -> void:
	#DebugDraw3D.draw_box(node._bottom_left_front, Quaternion.IDENTITY, node._size * expand, color)
	DebugDraw3D.draw_aabb(node._aabb, color)
	for i in node._children_nodes:
		if i in collision_nodes: draw_octotree(i, Color.GREEN, 1.01)
		else: draw_octotree(i, Color.BLUE)
	return
