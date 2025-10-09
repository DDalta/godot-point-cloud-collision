@tool
class_name PlyFile extends Resource

var num_vertex: int
var num_face: int
var vertices: PackedFloat32Array
var properties: Dictionary
var aabb: AABB
var octree: OctTree

var ascii := false

func _init(path=""):
	if !path.is_empty(): _parse(path)
	octree = OctTree.new(Vector3(-2.197177, -1.573868, -10.21991), Vector3(1.795723, 2.067532, -0.05456), 100)

func _parse(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var line = file.get_line().split(" ")
	
	var element = ""
	while not line[0] == "end_header":
		line = file.get_line().split(" ")
		match line[0]:
			"format":
				file.big_endian = line[1] == "binary_big_endian"
				self.ascii = line[1] == "ascii"
			"element":
				element = line[1]
				properties[element] = {}
				if element == "vertex": num_vertex = int(line[2])
				elif element == "face": num_face = int(line[2])
			"property":
				properties[element][line[2]] = line[1]
	
	if self.ascii:
		# if we are reading ascii .ply file
		for i in range(num_vertex):
			line = file.get_line().split(" ")
			var v: PackedFloat32Array
			for s in line:
				if !s.is_empty(): v.append(float(s))
			vertices.append_array(v)
	else:
		# if we are reading binary .ply file
		for i in range(num_vertex):
			for prop in self.properties["vertex"]:
				match self.properties["vertex"][prop]:
					"float": vertices.append(file.get_float())
					"uchar": vertices.append(file.get_8())
		# vertices = file.get_buffer(self.num_vertex * len(self.properties["vertex"]) * 4).to_float32_array()
		print("Loaded %d vertices" % [len(self.vertices)/10])

func _get_vertex_property_index(property: StringName) -> int:
	return self.properties["vertex"].keys().find(property)

func _update_aabb(point):
	if not self.aabb:
		self.aabb = AABB(point, Vector3.ZERO)
		return
	self.aabb = self.aabb.expand(point)

static func generate_mesh(pointcloud: PlyFile):
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_POINTS)
	
	for i in range(pointcloud.num_vertex):
		var index = i * len(pointcloud.properties["vertex"])
		
		var pos := Vector3(pointcloud.vertices[index+pointcloud._get_vertex_property_index("x")],
						pointcloud.vertices[index+pointcloud._get_vertex_property_index("y")],
						pointcloud.vertices[index+pointcloud._get_vertex_property_index("z")])
		
		var normal := Vector3(pointcloud.vertices[index+pointcloud._get_vertex_property_index("nx")],
			pointcloud.vertices[index+pointcloud._get_vertex_property_index("ny")],
			pointcloud.vertices[index+pointcloud._get_vertex_property_index("nz")])
		
		var color := Color(pointcloud.vertices[index+pointcloud._get_vertex_property_index("red")]/255,
						pointcloud.vertices[index+pointcloud._get_vertex_property_index("green")]/255,
						pointcloud.vertices[index+pointcloud._get_vertex_property_index("blue")]/255)
		
		st.set_color(color)
		st.set_normal(normal)
		st.add_vertex(pos)
		
		pointcloud.octree.insert(pos, {"color": color, "normal": normal})
		pointcloud._update_aabb(pos)
		
		#print("%f %f %f" % [pointcloud.vertices[index], pointcloud.vertices[index+1], pointcloud.vertices[index+2]])
	st.commit(mesh)
	return mesh

static func print_properties(pointcloud: PlyFile):
	print(pointcloud.properties)


		#for j in range(len(pointcloud.properties["vertex"])):
			#var prop = pointcloud.vertices[index + j]
		#st.set_color()
		#st.add_vertex()
