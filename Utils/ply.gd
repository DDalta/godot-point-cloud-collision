@tool
class_name PlyFile extends Resource

var num_vertex: int
var num_face: int
var vertices: PackedFloat32Array
var properties: Dictionary
var aabb: AABB

var ascii := false

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

func find_position(index: int) -> Vector3:
	return Vector3(self.vertices[index + self._get_vertex_property_index("x")],
			self.vertices[index + self._get_vertex_property_index("y")],
			self.vertices[index + self._get_vertex_property_index("z")])

func find_color(index: int) -> Color:
	return Color(self.vertices[index + self._get_vertex_property_index("red")]/255,
			self.vertices[index + self._get_vertex_property_index("green")]/255,
			self.vertices[index + self._get_vertex_property_index("blue")]/255)
	
func find_normal(index: int) -> Vector3:
	return Vector3(self.vertices[index + self._get_vertex_property_index("nx")],
			self.vertices[index + self._get_vertex_property_index("ny")],
			self.vertices[index + self._get_vertex_property_index("nz")])

static func print_properties(pointcloud: PlyFile):
	print(pointcloud.properties)
