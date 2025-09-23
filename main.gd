extends Node3D

const POINT_CLOUD = preload("res://Scenes/point_cloud.tscn")

var filepath := "res://Assets/PointClouds/TokyoAlleyway.ply"

func _ready() -> void:
	var pointcloud = PlyFile.new(filepath)
	
	PlyFile.print_properties(pointcloud)
	
	#var instance = POINT_CLOUD.instantiate()
	#instance.mesh = PlyFile.generate_mesh(pointcloud)
	#add_child(instance)
