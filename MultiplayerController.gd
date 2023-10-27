extends Control
@export var address = "127.0.0.1"
@export var port = 8910
#SERVER =
var peer 

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
@rpc("any_peer","call_local")
func startGame():
	var scene = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()
func peer_connected(id):
	print("Player "+str(id)+ " connected")
func peer_disconnected(id):
	print("Player "+str(id)+ "   	Disconnected")
func connected_to_server():
	print("connected to server")
func connection_failed():
	print("disconnected from server") 


func _on_host_button_down():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port,2)
	if  error!= OK:
		print("cannot host")
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for players")
	
	pass # Replace with function body.


func _on_join_button_down():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address,port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	pass # Replace with function body.


func _on_play_button_down():
	startGame.rpc()
	pass # Replace with function body.
