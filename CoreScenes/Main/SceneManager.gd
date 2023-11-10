extends Node

@export var PlayerScene : PackedScene
var index = 0 
# Called when the node enters the scene tree for the first time.
func _ready():
	for liftable in GameManager.Liftables.values():
		var chairloader :PackedScene= load(liftable["scene"])
		var chair := chairloader.instantiate()
		for property in liftable["setBeforeAdding"]:
			chair.set(property, liftable["setBeforeAdding"][property])
		add_child(chair)
		for property in liftable["setAfterAdding"]:
			chair.set(property, liftable["setAfterAdding"][property])


	for i in GameManager.Players:
		var player = PlayerScene.instantiate()
		player.name = str(GameManager.Players[i].id)
		add_child(player)
		var spawnpoints := get_tree().get_nodes_in_group("PlayerSpawnPoint")
		for spawnpoint in spawnpoints:
			if spawnpoint.name == str(index % len(spawnpoints)):
				player.global_position = spawnpoint.global_position 
		index+=1
	multiplayer.peer_connected.connect(add_player)
	
func add_player(id: int):
	var player = PlayerScene.instantiate()
	# Set player id.
	player.name = str(id)
	add_child(player)
	var spawnpointsN := get_tree().get_nodes_in_group("PlayerSpawnPoint")
	for spawnpointN in spawnpointsN:
		if spawnpointN.name == str(index % len(spawnpointsN)):
				player.global_position = spawnpointN.global_position 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
