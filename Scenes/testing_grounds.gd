@tool
extends Node3D

const RIGID_SPHERE = preload("res://Scenes/rigid_sphere.tscn")
const POINT_CLOUD = preload("res://Scenes/point_cloud_mesh.tscn")
@onready var point_cloud_mesh: MeshInstance3D = $PointCloud2
@onready var spheres: Node3D = $Spheres

@export var max_size: Vector3 = Vector3(10, 10, 10)
@export var enable_draw_octotree: bool = false
@export var point_count: int = 150
@export_tool_button("Regenerate Points") var gen_points_action = generate_points

var rtree: RTreeNode
var octree: OctTree
var collision_nodes: Array
var boundary_spheres: Dictionary

func _ready() -> void:
	octree = OctTree.new(Vector3(0, 0, 0), Vector3(20, 10, 20), 5)
	generate_points()

func _physics_process(delta: float) -> void:
	_update_point_cloud_collisions(octree)

func _process(delta: float) -> void:
	var a = DebugDraw3D.new_scoped_config().set_thickness(0.02)
	# collision_nodes = octree.check_intersection_aabb(AABB(csg_box_3d.global_position - (csg_box_3d.size / 2), csg_box_3d.size))
	if enable_draw_octotree: OctTree.draw_octree(octree, Color.BLUE)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("btn1"):
		var instance = RIGID_SPHERE.instantiate()
		spheres.add_child(instance)
		instance.radius = randf_range(0.1, 0.5)
		instance.global_position = Vector3(randf_range(0, 20), 5, randf_range(0, 20))

func generate_points():
	octree.clear()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_POINTS)
	
	var points = generate_plane()
	
	for i in points:
		octree.insert(i, {"color": "RED"})
		st.set_color(Color("RED"))
		st.add_vertex(i)
	st.commit(mesh)
	point_cloud_mesh.mesh = mesh

func generate_plane():
	var points = []
	var point = Vector3.ZERO
	for i in range(100):
		for j in range(100):
			points.append(point + Vector3(0, randf_range(0, 0.2), 0))
			point.x += 0.2
		point.z += 0.2
		point.x = 0
	return points

func _update_point_cloud_collisions(tree: OctTree):
	var previous_nodes = boundary_spheres.keys()
	var new_nodes = {} # set data structure using a dictionary
	for sphere in spheres.get_children():
		var intersecting_leaf_nodes = tree.check_intersection_sphere(sphere.global_position, sphere.radius)
		for node in intersecting_leaf_nodes:
			new_nodes[node] = true
	
	# first clear out previous intersecting nodes that are no longer being intersected
	for node: OctTree in previous_nodes:
		if not new_nodes.has(node) and boundary_spheres.has(node):
			for bs in boundary_spheres[node]:
				PhysicsServer3D.free_rid(bs)
			boundary_spheres.erase(node)
	
	# create collision spheres for each point in each node
	for node: OctTree in new_nodes:
		if boundary_spheres.has(node): continue
		boundary_spheres[node] = []
		for point in node._point_data:
				var bounding_sphere = PhysicsServer3D.body_create()
				var shape_rid = PhysicsServer3D.sphere_shape_create()
				var trans = Transform3D(Basis.IDENTITY, point)
				PhysicsServer3D.body_set_space(bounding_sphere, get_world_3d().space)
				PhysicsServer3D.shape_set_data(shape_rid, 0.05)
				PhysicsServer3D.body_add_shape(bounding_sphere, shape_rid)
				PhysicsServer3D.body_set_mode(bounding_sphere, PhysicsServer3D.BODY_MODE_STATIC)
				PhysicsServer3D.body_set_state(bounding_sphere, PhysicsServer3D.BODY_STATE_TRANSFORM, trans)
				boundary_spheres[node].append(bounding_sphere)
				
# obsolete function
func collide_point_cloud(a: OctTree, s_center: Vector3, s_radius: float):
	var intersecting_nodes = a.check_intersection_sphere(s_center, s_radius)
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
				PhysicsServer3D.shape_set_data(shape_rid, 0.05)
				PhysicsServer3D.body_add_shape(bounding_sphere, shape_rid)
				PhysicsServer3D.body_set_mode(bounding_sphere, PhysicsServer3D.BODY_MODE_STATIC)
				PhysicsServer3D.body_set_state(bounding_sphere, PhysicsServer3D.BODY_STATE_TRANSFORM, trans)
				boundary_spheres[node].append(bounding_sphere)

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
