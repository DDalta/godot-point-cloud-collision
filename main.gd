@tool
extends Node3D

@export var enable_draw_octotree: bool = false

@onready var sphere_rigid: RigidBody3D = $RigidBody3D
@onready var sphere_shape: CSGSphere3D = $RigidBody3D/CSGSphere3D


const POINT_CLOUD = preload("res://Scenes/point_cloud_mesh.tscn")

var filepath := "res://Assets/PointClouds/TokyoAlleyway.ply"
var pointcloud: PlyFile
var boundary_spheres: Dictionary

func _ready() -> void:
	pointcloud = PlyFile.new(filepath)
	
	var instance = POINT_CLOUD.instantiate()
	instance.mesh = PlyFile.generate_mesh(pointcloud)
	add_child(instance)
	print(pointcloud.aabb.position)
	print(pointcloud.aabb.size)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		sphere_rigid.global_position = Vector3(-0.038, -0.184, -2.494)
		sphere_rigid.linear_velocity = Vector3.ZERO
		sphere_rigid.angular_velocity = Vector3.ZERO

func _process(delta: float) -> void:
	var a = DebugDraw3D.new_scoped_config().set_thickness(0.01)
	if enable_draw_octotree: OctTree.draw_octree(pointcloud.octree, Color.BLUE)
	
func _physics_process(delta: float) -> void:
	collide_point_cloud(pointcloud.octree, sphere_rigid.global_position, sphere_shape.radius)

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
				PhysicsServer3D.shape_set_data(shape_rid, 0.01)
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
