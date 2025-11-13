extends Node3D

const RIGID_SPHERE = preload("res://Scenes/rigid_sphere.tscn")
const POINT_CLOUD = preload("res://Scenes/point_cloud_mesh.tscn")
@onready var point_cloud_mesh: MeshInstance3D = $PointCloud2
@onready var spheres: Node3D = $Spheres

@export var max_size: Vector3 = Vector3(10, 10, 10)
@export var enable_draw_octotree: bool = false
@export var point_count: int = 150
#@export_tool_button("Regenerate Points") var gen_points_action = generate_points

var octree: OctTree
var boundary_spheres: Dictionary
var ply_file: Array
var num_points: int = 0

func _ready() -> void:
	octree = OctTree.new(Vector3(0, 0, 0), Vector3(20, 10, 20), 5)
	mimic_ply_extraction()

func _physics_process(delta: float) -> void:
	_update_point_cloud_collisions()
	_debug_colliding_points()

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

func mimic_ply_extraction():
	ply_file = generate_point_data()
	build_mesh()
	build_octree()

func generate_point_data():
	num_points = 0
	var point_data = []
	var point = Vector3.ZERO
	for i in range(100):
		for j in range(100):
			# x, y, z, r, b, g in array

			point_data.append(point.x)
			point_data.append(randf_range(0, 0.2))
			point_data.append(point.z)
			point_data.append(1.0)
			point_data.append(0.0)
			point_data.append(0.0)
			num_points += 1
			
			point.x += 0.2
		point.z += 0.2
		point.x = 0
	return point_data

func build_octree():
	octree.clear()
	for i in range(num_points):
		var point_index = i * 6
		var point = Vector3(ply_file[point_index], ply_file[point_index+1], ply_file[point_index+2])
		octree.insert(point, point_index, ply_file)

func build_mesh():
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_POINTS)
	
	for i in range(num_points):
		var point_index = i * 6
		var point = Vector3(ply_file[point_index], ply_file[point_index+1], ply_file[point_index+2])
		var color = Color(ply_file[point_index+3], ply_file[point_index+4], ply_file[point_index+5])
		for node: OctTree in boundary_spheres.keys():
			if node.intersects_point(point):
				color = Color.GREEN
		
		st.set_color(color)
		st.add_vertex(point)
	st.commit(mesh)
	point_cloud_mesh.mesh = mesh

func _update_point_cloud_collisions():
	var previous_nodes = boundary_spheres.keys()
	var new_nodes = {} # set data structure using a dictionary
	for sphere in spheres.get_children():
		var intersecting_leaf_nodes = octree.check_intersection_sphere(sphere.global_position, sphere.radius)
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
		for idx in node._point_data:
			var point_position = Vector3(ply_file[idx], ply_file[idx+1], ply_file[idx+2])
			var bounding_sphere = PhysicsServer3D.body_create()
			var shape_rid = PhysicsServer3D.sphere_shape_create()
			var trans = Transform3D(Basis.IDENTITY, point_position)
			PhysicsServer3D.body_set_space(bounding_sphere, get_world_3d().space)
			PhysicsServer3D.shape_set_data(shape_rid, 0.05)
			PhysicsServer3D.body_add_shape(bounding_sphere, shape_rid)
			PhysicsServer3D.body_set_mode(bounding_sphere, PhysicsServer3D.BODY_MODE_STATIC)
			PhysicsServer3D.body_set_state(bounding_sphere, PhysicsServer3D.BODY_STATE_TRANSFORM, trans)
			boundary_spheres[node].append(bounding_sphere)

func _debug_colliding_points():
	for node: OctTree in boundary_spheres.keys():
		if not node._point_data.is_empty():
			DebugDraw3D.draw_aabb(node._aabb, Color.GREEN)
