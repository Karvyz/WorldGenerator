extends Node
class_name Chunk

const sizeChunk = 200;
var density

var chunk
var terrain
var raycast


var lastChunk

var noise
var noise2
var worldHeight

const scaleHeight = 10
const scaleWidth = 10

var position
var distance
var parentNode

var grassDensity



static func getSizeChunk(): return sizeChunk

func setup(position, distance, parentNode):
	self.position = position
	self.distance = distance
	self.parentNode = parentNode
	
	worldHeight = OpenSimplexNoise.new()
	worldHeight.period = 10 * scaleWidth
	worldHeight.octaves = 1
	
	
	grassDensity = 4 / pow(1.3,distance)
#	density = 1 / pow(1.08,distance)
	density = 1 / pow(1.1,distance)
	noise = OpenSimplexNoise.new()
	noise.period = scaleWidth
	noise.octaves = 1
	noise2 = OpenSimplexNoise.new()
	noise2.period = 10*scaleWidth
	noise2.octaves = 1
	chunk = Spatial.new()
	chunk.translate(Vector3(position.x * sizeChunk , 0, position.z * sizeChunk))
	raycast = RayCast.new()
#	raycast.enabled = true
#	raycast.collide_with_areas = true
#	raycast.exclude_parent = false
	chunk.add_child(raycast)

func generateTerrain():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(sizeChunk,sizeChunk)
	plane_mesh.subdivide_depth = sizeChunk * density
	plane_mesh.subdivide_width = sizeChunk * density
	
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(plane_mesh, 0)
	
	var array_plane = surface_tool.commit()
	
	var data_tool = MeshDataTool.new()
	
	data_tool.create_from_surface(array_plane, 0)
	
	for i in range(data_tool.get_vertex_count()):
		var vertex = data_tool.get_vertex(i)
		vertex.y = getHeight4(vertex.x + position.x * sizeChunk, vertex.z + position.z * sizeChunk)
		data_tool.set_vertex(i, vertex)
		
	for i in range(array_plane.get_surface_count()):
		array_plane.surface_remove(i)
		
	data_tool.commit_to_surface(array_plane)
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.create_from(array_plane, 0)
	surface_tool.generate_normals()
	
	var mesh_instance = MeshInstance.new()
	mesh_instance.mesh = surface_tool.commit()
	var mat = preload("res://Materials/Terrain/Terrain.tres")
#	mat.albedo_color = Color(rand_range(0,1),rand_range(0,1),rand_range(0,1))
	mesh_instance.set_surface_material(0, mat)
	mesh_instance.create_trimesh_collision()
	terrain = mesh_instance
#	print("n + " + terrain.get_mesh().get_surface_count())
	chunk.add_child(mesh_instance)

func generateWater():
	var waterMesh = PlaneMesh.new()
	waterMesh.size = Vector2(sizeChunk, sizeChunk)
	waterMesh.subdivide_depth = 2
	waterMesh.subdivide_width = 2
	var water = MeshInstance.new()
	water.mesh = waterMesh
	var mat = preload("res://Materials/Water/Water.tres")
#	mat.albedo_color = Color(rand_range(0,1),rand_range(0,1),rand_range(0,1))
	water.set_surface_material(0, mat)
#	water.translate(Vector3(0, 0.1, 0))
	chunk.add_child(water)

func generateGrass():
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var test = MultiMesh.new()
	test.mesh = preload("res://assets/Grass/grass_triangle.obj")
	test.mesh.surface_set_material(0, preload("res://Materials/wind_grass.tres"))

	test.transform_format = MultiMesh.TRANSFORM_3D
	test.custom_data_format = MultiMesh.CUSTOM_DATA_NONE
	# Then resize (otherwise, changing the format is not allowed).
	var multimesh = MultiMeshInstance.new()
	multimesh.multimesh = test
	# Set the transform of the instances.
	test.instance_count = sizeChunk * sizeChunk * grassDensity

	for i in range(test.instance_count):
		var x = rand_range(-sizeChunk/2, sizeChunk/2)
		var z = rand_range(-sizeChunk/2, sizeChunk/2)
#		var position = Transform()
#		position.basis.rotated(Vector3(0,1,0), deg2rad(rand_range(0,90)))
##		position = position.rotated()
#		position = position.translated(Vector3(x, getHeight3(x, z) - 0.2, z))
		var transform := Transform().rotated(Vector3.UP, rng.randf_range(-PI / 2, PI / 2))
		transform.origin = Vector3(x, getHeight4(x + position.x * sizeChunk, z + position.z * sizeChunk), z)
		test.set_instance_transform(i, transform)
	chunk.add_child(multimesh)


func getHeight4(x, z):
	var elevation = log(worldHeight.get_noise_2d(x, z) + 1) + 0.2
	return elevation * scaleHeight


func getHeight3(x, z):
	var temp = noise2.get_noise_2d(x, z) + 0.3
	if temp < 0: return -temp*temp + 1
	var e0 = 1 * ridgeNoise(1 * x, 1 * z);
	var e1 = 0.5 * ridgeNoise(2 * x, 2 * z) * e0;
	var e2 = 0.25 * ridgeNoise(4 * x, 4 * z) * (e0+e1);
	var e = (e0 + e1 + e2) / (1 + 0.5 + 0.25);
	e = e + 1
	var temp2 = e * temp * temp * 2
	return temp2 * scaleWidth + 1


func getHeight2(x, z):
	var e0 = 1 * ridgeNoise(1 * x, 1 * z);
	var e1 = 0.5 * ridgeNoise(2 * x, 2 * z) * e0;
	var e2 = 0.25 * ridgeNoise(4 * x, 4 * z) * (e0+e1);
	var e = (e0 + e1 + e2) / (1 + 0.5 + 0.25);
	var temp = e * pow(noise2.get_noise_2d(x, z), 2) * 2
	return temp


func ridgeNoise(x, z):
	return 2 * (0.5 - abs(0.5 - noise.get_noise_2d(x,z)))

func getHeight(x, z):
#	var elevation = 1 * noise.get_noise_2d(x, z) + 0.5 * noise.get_noise_2d(2*x, 2*z) + 0.25 * noise.get_noise_2d(4*x, 4*z)
#	var elevation = 1 * ridgeNoise(x, z) + 0.5 * ridgeNoise(2*x, 2*z) + 0.25 * ridgeNoise(4*x, 4*z)
	var e0 = 1 * ridgeNoise(1 * x, 1 * z);
	var e1 = 0.5 * ridgeNoise(2 * x, 2 * z) * e0;
	var e2 = 0.25 * ridgeNoise(4 * x, 4 * z) * (e0+e1);
	var e = (e0 + e1 + e2) / (1 + 0.5 + 0.25);
	var temp = pow(e, 1.2)
	if is_nan(temp):
		return 0.0
	return scaleHeight * temp


func attach():
	parentNode.call_deferred("add_child", chunk)
