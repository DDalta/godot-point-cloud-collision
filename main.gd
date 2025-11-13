extends Node3D

@onready var spheres: Node3D = $Spheres
@onready var free_camera: Camera3D = $FreeCamera

@export var enable_draw_octotree: bool = false

const RIGID_SPHERE = preload("res://Scenes/rigid_sphere.tscn")
const POINT_CLOUD = preload("res://Scenes/point_cloud_mesh.tscn")

var filepath := "res://Assets/PointClouds/TokyoAlleyway.ply"
var pointcloud: PlyFile
var boundary_spheres: Dictionary
var octree: OctTree

func _ready() -> void:
	# read and parse file
	pointcloud = PlyFile.new(filepath)
	
	# build pointcloud mesh
	var instance = POINT_CLOUD.instantiate()
	instance.mesh = build_mesh()
	add_child(instance)
	print("Built mesh!")
	
	# build spacial octree
	octree = OctTree.new(Vector3(-2.197177, -1.573868, -10.21991), Vector3(1.795723, 2.067532, -0.05456), 100)
	build_octree()
	print("Built octree!")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("btn1"):
		
		var instance = RIGID_SPHERE.instantiate()
		spheres.add_child(instance)
		instance.radius = randf_range(0.1, 0.25)
		instance.global_position = free_camera.global_position + (-free_camera.basis.z * 2)

func _physics_process(delta: float) -> void:
	var a = DebugDraw3D.new_scoped_config().set_thickness(0.01)
	_update_point_cloud_collisions()
	if enable_draw_octotree: OctTree.draw_octree(pointcloud.octree, Color.BLUE)
	_debug_colliding_points()

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
			var point_position = pointcloud.find_position(idx)
			var bounding_sphere = PhysicsServer3D.body_create()
			var shape_rid = PhysicsServer3D.sphere_shape_create()
			var trans = Transform3D(Basis.IDENTITY, point_position)
			PhysicsServer3D.body_set_space(bounding_sphere, get_world_3d().space)
			PhysicsServer3D.shape_set_data(shape_rid, 0.01)
			PhysicsServer3D.body_add_shape(bounding_sphere, shape_rid)
			PhysicsServer3D.body_set_mode(bounding_sphere, PhysicsServer3D.BODY_MODE_STATIC)
			PhysicsServer3D.body_set_state(bounding_sphere, PhysicsServer3D.BODY_STATE_TRANSFORM, trans)
			boundary_spheres[node].append(bounding_sphere)

func build_octree():
	if not octree._children_nodes.is_empty():
		octree.clear()
	
	for i in range(pointcloud.num_vertex):
		var index = i * len(pointcloud.properties["vertex"])
		var point_position = pointcloud.find_position(index)
		octree.insert(point_position, index, pointcloud)

func build_mesh():
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_POINTS)
	
	for i in range(pointcloud.num_vertex):
		var index = i * len(pointcloud.properties["vertex"])
		var point_position = pointcloud.find_position(index)
		var color = pointcloud.find_color(index)
		for node: OctTree in boundary_spheres.keys():
			if node.intersects_point(point_position):
				color = Color.GREEN
		
		st.set_color(color)
		st.add_vertex(point_position)
	st.commit(mesh)
	return mesh

func _debug_colliding_points():
	for node: OctTree in boundary_spheres.keys():
		DebugDraw3D.draw_aabb(node._aabb, Color.GREEN)
