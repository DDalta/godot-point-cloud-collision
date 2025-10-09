@tool
extends Node3D

const WIREFRAME = preload("res://Shader/wireframe.tres")
const POINT_CLOUD = preload("res://Scenes/point_cloud_mesh.tscn")
@onready var point_cloud_mesh: MeshInstance3D = $PointCloud2
@onready var rigid_body_3d: RigidBody3D = $RigidBody3D
@onready var csg_box_3d: CSGBox3D = $RigidBody3D/CSGBox3D
@onready var csg_sphere_3d: CSGSphere3D = $CSGSphere3D

@export var max_size: Vector3 = Vector3(10, 10, 10)
@export var enable_draw_octotree: bool = false
@export var point_count: int = 150
@export_tool_button("Regenerate Points") var gen_points_action = generate_points

var rtree: RTreeNode
var octree: OctTree
var collision_nodes: Array
var boundary_spheres: Dictionary

func _ready() -> void:
	octree = OctTree.new(Vector3(0, 0, 0), Vector3(10, 10, 10), 5)
	generate_points()

func _physics_process(delta: float) -> void:
	collide_point_cloud(octree, AABB(csg_box_3d.global_position - (csg_box_3d.size / 2), csg_box_3d.size))

func _process(delta: float) -> void:
	var a = DebugDraw3D.new_scoped_config().set_thickness(0.02)
	# collision_nodes = octree.check_intersection_aabb(AABB(csg_box_3d.global_position - (csg_box_3d.size / 2), csg_box_3d.size))
	if enable_draw_octotree: draw_octotree(octree, Color.BLUE)

func _input(event: InputEvent) -> void:
	if event.is_action("ui_accept"):
		rigid_body_3d.global_position = Vector3(5, 12, 5)
		rigid_body_3d.linear_velocity = Vector3.ZERO
		rigid_body_3d.angular_velocity = Vector3.ZERO

func generate_points():
	octree.clear()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_POINTS)
	
	for i in range(point_count):
		var point = Vector3(randf_range(0, 10), randf_range(0, 10), randf_range(0, 10))
		octree.insert(point, "")
		st.set_color(Color.RED)
		st.add_vertex(point)
	st.commit(mesh)
	point_cloud_mesh.mesh = mesh
	#RTreeNode.print_rtree(rtree)

func collide_point_cloud(a: OctTree, b: AABB):
	var intersecting_nodes = a.check_intersection_aabb(b)
	if intersecting_nodes: # if a and b are intersecting

		# first clean out previous intersecting nodes that are no longer being intersected
		var previous_nodes = boundary_spheres.keys()
		for node in previous_nodes:
			if not intersecting_nodes.find(node) >= 0:
				for bs in boundary_spheres[node]:
					PhysicsServer3D.free_rid(bs)
				boundary_spheres.erase(node)
		
		# create collision spheres for each point in each node
		for node: OctTree in intersecting_nodes:
			if boundary_spheres.has(node): continue
			boundary_spheres[node] = []
			for point in node._point_data:
				var bounding_sphere = PhysicsServer3D.body_create()
				var shape_rid = PhysicsServer3D.sphere_shape_create()
				var trans = Transform3D(Basis.IDENTITY, point)
				PhysicsServer3D.body_set_space(bounding_sphere, get_world_3d().space)
				PhysicsServer3D.shape_set_data(shape_rid, 0.1)
				PhysicsServer3D.body_add_shape(bounding_sphere, shape_rid)
				PhysicsServer3D.body_set_mode(bounding_sphere, PhysicsServer3D.BODY_MODE_STATIC)
				PhysicsServer3D.body_set_state(bounding_sphere, PhysicsServer3D.BODY_STATE_TRANSFORM, trans)
				boundary_spheres[node].append(bounding_sphere)
	else:
		# we are not intersecting with anything so just clear bs dictionary
		for node in boundary_spheres:
			for bs in boundary_spheres[node]:
				PhysicsServer3D.free_rid(bs)
		boundary_spheres.clear()

func draw_rtree(node: RTreeNode):
	if node._parent == null:
		DebugDraw3D.draw_aabb(node.get_aabb().grow(0.01), Color.RED)
	elif node._children_nodes.is_empty():
		if node.get_aabb():
			DebugDraw3D.draw_aabb(node.get_aabb(), Color.GREEN)
		else:
			DebugDraw3D.draw_aabb(node.get_aabb().grow(0.01), Color.GREEN)
		for point in node._point_data:
			DebugDraw3D.draw_text(point + Vector3(0, 0.2, 0), "%v" % point)
	else:
		DebugDraw3D.draw_aabb(node.get_aabb(), Color.BLUE)
	
	for child: RTreeNode in node._children_nodes:
		draw_rtree(child)

func draw_octotree(node: OctTree, color: Color, expand: float = 1.0) -> void:
	#DebugDraw3D.draw_box(node._bottom_left_front, Quaternion.IDENTITY, node._size * expand, color)
	DebugDraw3D.draw_aabb(node._aabb, color)
	for i in node._children_nodes:
		if i in collision_nodes: draw_octotree(i, Color.GREEN)
		else: draw_octotree(i, Color.BLUE)
	return
