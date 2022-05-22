extends Spatial

var sizeChunk
var renderDistance = 5
var lastChunk
var location = {}

var worldNode

const numberThreads = 11
var threadChunk


var working
var threads = []
var chunkList = []

func _ready():
	
	threadChunk = Thread.new()
	worldNode = get_tree().root.get_node("World")
	sizeChunk = Chunk.getSizeChunk()
	for i in range(numberThreads):
		threads.push_back(Thread.new())
	print("letsgo")	
#	var chunk = chunkGenerator.generateChunk(currentChunk)
#	get_tree().root.get_node("World").call_deferred("add_child", chunk)
#	get_tree().root.get_node("World/Chunks").generateChunk(currentChunk)


func tempo(data):
	var chunk = Chunk.new()
	chunk.setup(data[0], data[1], worldNode)
	chunk.generateTerrain()
	chunk.generateWater()
#	chunk.generateGrass()
	chunk.attach()
	print(data[0])
#	return chunkGenerator.generateChunk(position)

func updateChunks(currentChunk):
	var chunkList = chunkList(currentChunk)
	for i in chunkList.size():
		if !location.has(chunkList[i]):
			tempo(chunkList[i])
			location[chunkList[i]] = true
	lastChunk = currentChunk


func Coordonate(x,z):
	return Vector3(int(x)/sizeChunk, 0, int(z)/sizeChunk)
	

func _process(_delta):
	for i in range(numberThreads):
		if threads[i].is_active():
			if !threads[i].is_alive():
				threads[i].wait_to_finish()
				threads[i] = Thread.new()
				
	var currentChunk = Coordonate(get_parent().global_transform.origin.x,get_parent().global_transform.origin.z)
	if currentChunk != lastChunk:
		chunkList = chunkList(currentChunk)
		lastChunk = currentChunk
	
	if chunkList.size() > 0:
		for i in range(numberThreads):
			if chunkList.size() == 0: break
			if !threads[i].is_active():
				threads[i].start(self, "tempo", chunkList.pop_front(), 1)

func chunkList(position):
	var chunkList = []
	chunkList.push_back([position, 0])
	for distance in range(1, renderDistance + 1):
		for x in range(position.x - distance, position.x + distance + 1):
			for z in [position.z - distance, position.z + distance]:
				chunkList.push_back([Vector3(x,0,z), distance])
		for z in range(position.z - distance + 1, position.z + distance):
			for x in [position.x - distance, position.x + distance]:
				chunkList.push_back([Vector3(x,0,z), distance])
#	for i in chunkList.size():
#		print(chunkList[i])
	return chunkList

