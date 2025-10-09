class_name SphereCollision

# https://gamedev.stackexchange.com/questions/156870/how-do-i-implement-a-aabb-sphere-collision
static func _get_closest_aabb_point(aabb: AABB, sphere_center: Vector3) -> Vector3:
	var closest_point = Vector3()
	closest_point.x = clamp(sphere_center.x, aabb.position.x, aabb.position.x + aabb.size.x)
	closest_point.y = clamp(sphere_center.y, aabb.position.y, aabb.position.y + aabb.size.y)
	closest_point.z = clamp(sphere_center.z, aabb.position.z, aabb.position.z + aabb.size.z)
	return closest_point

static func check_sphere_aabb_intersection(sphere_center: Vector3, sphere_radius: float, aabb: AABB) -> bool:
	var closest_point = _get_closest_aabb_point(aabb, sphere_center)
	var distance_squared = sphere_center.distance_squared_to(closest_point)
	# Sphere and AABB intersect if the (squared) distance between them is less than the (squared) sphere radius.
	return distance_squared <= (sphere_radius * sphere_radius)
