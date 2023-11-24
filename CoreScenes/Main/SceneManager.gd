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
		spawn_player( str(GameManager.Players[i].id), GameManager.Players[i].username )
		
	$CanvasLayer.hide()

@rpc("any_peer", "call_local")
func spawn_player(id, username):
	var player = PlayerScene.instantiate()
	player.name = id
	player.username = username
	add_child(player)
	var spawnpoints := get_tree().get_nodes_in_group("PlayerSpawnPoint")
	for spawnpoint in spawnpoints:
		if spawnpoint.name == str(index % len(spawnpoints)):
			player.global_position = spawnpoint.global_position 
	index+=1


func _on_respawn_pressed():
	spawn_player.rpc( str(multiplayer.get_unique_id()),$CanvasLayer/Control/LineEdit.text  )
	$CanvasLayer.hide()




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass








