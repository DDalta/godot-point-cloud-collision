extends RigidBody3D

@onready var csg_sphere_3d: CSGSphere3D = $CSGSphere3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var radius: float = 0.5:
	set(radius):
		csg_sphere_3d.radius = radius
		collision_shape_3d.shape.radius = radius

func _ready() -> void:
	csg_sphere_3d.radius = radius
	var collision_shape = SphereShape3D.new()
	collision_shape.radius = radius
	collision_shape_3d.shape = collision_shape
