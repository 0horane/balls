extends Control
@export var address = "127.0.0.1"
@export var port = 3150
#SERVER =
var peer 

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if "--server" in OS.get_cmdline_args():
		host_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
@rpc("any_peer","call_local")
func startGame():
	var scene = load("res://CoreScenes/Main/main.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()
	
	
func peer_connected(id): # runs on all
	print("Player "+str(id)+ " connected")
	
	
func peer_disconnected(id): #runs on all
	print("Player "+str(id)+ "   	Disconnected")
	
	
func connected_to_server(): # from client
	print("connected to server")
	$IPPrompt/ConnectionTimeout.stop()
	showError("connected to server")
	$IPPrompt.hide()
	SendPlayerInformaction.rpc_id(1,$TextEdit.text, multiplayer.get_unique_id())
	
	
func connection_failed(): # from client
	print("disconnected from server") 
	showError("disconnected to server")
	
	
@rpc("any_peer")
func SendPlayerInformaction(username,id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] ={
			"username": username,
			"id":id,
		}
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformaction.rpc(GameManager.Players[i].username, i)


@rpc("authority", "call_local")
func SendObjectInformaction(object):
	if !GameManager.Liftables.has(object["id"]):
		GameManager.Liftables[object["id"]] = object
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendObjectInformaction.rpc(GameManager.Players[i].username, i)
			
			
@rpc("any_peer","call_local")
func _on_host_button_down():
	host_game()
	SendPlayerInformaction($TextEdit.text, multiplayer.get_unique_id())

func host_game():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port,32)
	if  error!= OK:
		showError("Error attempting to host")
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for players")


func _on_join_button_down():
	$IPPrompt/Label.text = "Ingresar dirección de IP"
	$IPPrompt.show()
	$IPPrompt/IPInput.grab_focus()
	



func _on_play_button_down():
	if multiplayer.is_server() and peer:
		for i in range(100):
			var size := randf_range(0,1)**2+0.2
			SendObjectInformaction.rpc({
					"id":i,
					"scene": "res://ObjectScenes/chair.tscn",
					"setBeforeAdding": {
						"size": size,
						"mass": size**3 *1000
					}, 
					"setAfterAdding": {
						"global_position": Vector3(randf_range(-20, 20), 5,randf_range(-20, 20)),
						"global_rotation": Vector3(0, randf_range(0, 2*PI),0)
					} 
				})
		
		
		startGame.rpc()
	else:
		showError("Not the host")


func _on_ok_ip_button_pressed(_text=null):
	peer = ENetMultiplayerPeer.new()
	peer.create_client($IPPrompt/IPInput.text,port)
	if peer==null || peer.get_host()==null:
		showError("Dirección inválida / incorrecta")
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	$IPPrompt/ConnectionTimeout.start(2)
	


func _on_ip_prompt_close_requested():
	$IPPrompt.hide()


func _on_error_close_requested():
	$Error.hide()



func _on_connection_timeout_timeout():
	showError("nO SE PUDO CONECTAR")


func showError(errortext:String):
	$Error/ErrorMessage.text = errortext
	$Error.show()


