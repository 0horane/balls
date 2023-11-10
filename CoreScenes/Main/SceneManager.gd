extends Node 

@export var PlayerScene : PackedScene

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

	var index = 0 
	for i in GameManager.Players:
		var player = PlayerScene.instantiate()
		player.name = str(GameManager.Players[i].id)
		add_child(player)
		var spawnpoints := get_tree().get_nodes_in_group("PlayerSpawnPoint")
		for spawnpoint in spawnpoints:
			if spawnpoint.name == str(index % len(spawnpoints)):
				player.global_position = spawnpoint.global_position 
		index+=1
	multiplayer.peer_connected.connect(peer_connected)

func peer_connected(id):
	if multiplayer.is_server():
		if get_tree().current_scene.name == "main":
			var character = preload("res://CoreScenes/Player/player.tscn").instantiate()
			character.player = id
			startGame(id).rpc(GameManager.Players[id].id,id)
			# Set player id.
@rpc("any_peer","call_local")
func startGame(id):
	if !get_tree().current_scene.name == "main":
		
		var scene = load("res://CoreScenes/Main/main.tscn").instantiate()
		get_tree().root.add_child(scene)

	
	
#multiplayer.peer_connected.connect(add_player)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
