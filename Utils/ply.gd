class_name PlyFile extends Resource

var num_vertex: int
var num_face: int
var vertices: PackedFloat32Array
var properties: Dictionary

func _init(path=""):
	if !path.is_empty(): _parse(path)

func _parse(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var line = file.get_line().split(" ")
	
	var element = ""
	while not line[0] == "end_header":
		line = file.get_line().split(" ")
		match line[0]:
			"format":
				file.big_endian = line[1] == "binary_big_endian"
			"element":
				element = line[1]
				properties[element] = []
				if element == "vertex": num_vertex = int(line[2])
				elif element == "face": num_face = int(line[2])
			"property":
				properties[element].append({line[2]: line[1]})
	
	if file.big_endian:
		# if we are reading binary .ply file
		vertices = file.get_buffer(num_vertex * len(properties["vertex"]) * 4).to_float32_array()
	else:
		# if we are reading ascii .ply file
		for i in range(num_vertex):
			line = file.get_line().split(" ")
			var v: PackedFloat32Array
			for s in line:
				if !s.is_empty(): v.append(float(s))
			vertices.append_array(v)
		
static func generate_mesh(pointcloud: PlyFile):
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_POINTS)
	
	for i in range(pointcloud.num_vertex):
		var index = i * len(pointcloud.properties["vertex"])
		st.set_color(Color(pointcloud.vertices[index+3]/255,
							pointcloud.vertices[index+4]/255,
							pointcloud.vertices[index+5]/255))
		st.add_vertex(Vector3(pointcloud.vertices[index], 
							pointcloud.vertices[index+1], 
							pointcloud.vertices[index+2]))

		#print("%f %f %f" % [pointcloud.vertices[index], pointcloud.vertices[index+1], pointcloud.vertices[index+2]])
	st.commit(mesh)
	return mesh

static func print_properties(pointcloud: PlyFile):
	print(pointcloud.properties)


		#for j in range(len(pointcloud.properties["vertex"])):
			#var prop = pointcloud.vertices[index + j]
		#st.set_color()
		#st.add_vertex()
