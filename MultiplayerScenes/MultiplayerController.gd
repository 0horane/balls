extends Control

@export var address = "127.0.0.1"
@export var port = 3150
#SERVER =
var peer 
#Declaring Objects
@onready var log = get_node("LogCont/RichTextLabel")
@onready var IPlabel = get_node("IPPrompt/Label")
@onready var IPPrompt = get_node("IPPrompt")
@onready var IpPromptTimeout = get_node("IPPrompt/ConnectionTimeout")
@onready var IPPromptText = get_node("IPPrompt/IPInput")
@onready var PlayerNameTextbokx = get_node("NamePlayer/Player_Name")
@onready var PlayerNameWindow = get_node("NamePlayer")
@onready var PlayerNameButton = get_node("NamePlayer/SelectName")
var PlayerName = ""
var randomcolorGropus = [
	"#99ccff",
	"e699ff"
]

var scenelist1 = [
	#"res://ObjectScenes/chair.tscn", 
	#"res://ObjectScenes/arbol1.tscn",
	#"res://ObjectScenes/arbol2.tscn",
	#"res://ObjectScenes/basura.tscn",
	"res://ObjectScenes/chair.tscn",
	"res://ObjectScenes/craneo.tscn",
	"res://ObjectScenes/gato.tscn",
	"res://ObjectScenes/gnomo.tscn",
	"res://ObjectScenes/gun1.tscn",
	"res://ObjectScenes/gun2.tscn",
	#"res://ObjectScenes/lamparota.tscn",
	"res://ObjectScenes/mesa.tscn",
	"res://ObjectScenes/piedra1.tscn",
	"res://ObjectScenes/piedra2.tscn",
	"res://ObjectScenes/piedra3.tscn",
	"res://ObjectScenes/piedra4.tscn",
	#"res://ObjectScenes/silla2.tscn",
	"res://ObjectScenes/rama3.tscn",
	"res://ObjectScenes/rama2.tscn",
	"res://ObjectScenes/rama1.tscn",
	#"res://ObjectScenes/planta.tscn",
	"res://ObjectScenes/piedra6.tscn",
	"res://ObjectScenes/piedra5.tscn",
	"res://ObjectScenes/bicicleta.tscn",
	#"res://ObjectScenes/auto.tscn",
]
var scenelist2 = [
	"res://ObjectScenes/piedra1.tscn",
	"res://ObjectScenes/piedra2.tscn",
	"res://ObjectScenes/piedra3.tscn",
	"res://ObjectScenes/piedra4.tscn",
	"res://ObjectScenes/rama3.tscn",
	"res://ObjectScenes/rama2.tscn",
	"res://ObjectScenes/rama1.tscn",
	"res://ObjectScenes/piedra6.tscn",
	"res://ObjectScenes/piedra5.tscn",
]

var soloambiente=true


func _ready():
	#Engine.time_scale=0.25
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if "--server" in OS.get_cmdline_args():
		host_game()
	PlayerNameWindow.show()
	PlayerNameTextbokx.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

@rpc("any_peer","call_local")
func startGame():
	var scene = load("res://CoreScenes/Main/main.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()
	
	
func peer_connected(id): # runs on all
	PlayersConnectedText(id)
	print("Player "+str(id)+ " connected")
	
	
func peer_disconnected(id): #runs on all
	PlayersConnectedText(id)
	print("Player "+str(id)+ "   	Disconnected")
	

func connected_to_server(): # from client
	print("connected to server")
	IpPromptTimeout.stop()
	showError("connected to server")
	IPPrompt.hide()
	SendPlayerInformaction.rpc_id(1,PlayerNameTextbokx.text, multiplayer.get_unique_id())
	
	
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
		#for i in GameManager.Players:
		#	SendObjectInformaction.rpc_id(int(GameManager.Players[i].username), object)
		pass	
			
@rpc("any_peer","call_local")
func _on_host_button_down():
	host_game()
	SendPlayerInformaction(PlayerNameTextbokx.text, multiplayer.get_unique_id())

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
	IPlabel.text = "Ingresar dirección de IP"
	IPPrompt.show()
	IPPromptText.grab_focus() # Replace with function body.
	


func _on_play_button_down():
	if multiplayer.is_server() and peer:
		var usedscenes = scenelist2 if soloambiente else scenelist1
		
		
		for i in range($Conf/Objcount.value):
			var size :float= max(0.0, randfn(1,1))+0.1  #randf_range(0,3)**2+0.2
			SendObjectInformaction.rpc({
					"id":i,
					"scene": usedscenes.pick_random(),
					"setBeforeAdding": {
						"size": size,
						
					}, 
					"setAfterAdding": {
						"global_position": Vector3(randfn(0, 100*size), 5,randfn(0, 100*size)), 
						"global_rotation": Vector3(0, randf_range(0, 2*PI),0),
						"mass": size**3 *1000
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
	
func _on_select_name_button_down():
	PlayerName = PlayerNameTextbokx.text
	PlayerNameWindow.hide()


func _on_ip_prompt_close_requested():
	IPPrompt.hide()


func _on_error_close_requested():
	$Error.hide()


func PlayersConnectedText(id):
	if multiplayer.is_server() and peer:
		log.clear()
		for Player in GameManager.Players :
			print(Player)
			log.append_text('[color=green] '+ GameManager.Players[Player].username +'[/color] Connected')
			log.append_text('\n')
		#//log.bbcode_text += '/n'
		#log.bbcode_text += '/n'
		
		#$LogCont/RichTextLabel += '[ color = ' +randomcolorGropus[0]+ ']'
func _on_connection_timeout_timeout():
	showError("nO SE PUDO CONECTAR")


func showError(errortext:String):
	$Error/ErrorMessage.text = errortext
	$Error.show()






func _on_liftable_category_toggled(button_pressed):
	soloambiente = not soloambiente
