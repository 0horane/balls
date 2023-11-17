@tool
extends Marker3D
@export var sin_gravedad := false
@export var anti_vibracion := false
@export var max_living_spawns:=5
var current_spawns=1

@export var size:float:
	get:
		return sizestore 
	set(value):
		sizestore = value
		if is_instance_valid(chair_instance) || Engine.is_editor_hint():
			queue_free_chair()
			spawn_chair()
		
var sizestore:float=1
var spawncount:=0



@export var chair_scene : PackedScene:
	get:
		return chair_scene_store 
	set(value):
		chair_scene_store = value
		if is_instance_valid(chair_instance) || Engine.is_editor_hint():
			queue_free_chair()
			spawn_chair()

var chair_scene_store : PackedScene = preload("res://ObjectScenes/chair.tscn")


var chair_instance : Node3D
var spawn_timer : Timer
var check_timer : Timer
var player_group : String = "balls"
var replacement_timer_duration : float = 5

func _ready():
	if !Engine.is_editor_hint():
		spawn_timer = Timer.new()
		check_timer = Timer.new()
		setup_timers()
	queue_free_chair()
	spawn_chair()
	
	
func setup_timers():

	spawn_timer.wait_time = 30 # change to 30 later
	check_timer.wait_time = 30

	spawn_timer.one_shot = true
	check_timer.one_shot = true

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	check_timer.timeout.connect(_on_check_timer_timeout)
	
	add_child(spawn_timer)
	add_child(check_timer)
	
	check_timer.start()
	
func spawn_chair(newspawn:bool=false):
	if chair_scene:
		chair_instance = chair_scene.instantiate()
		chair_instance.name = name+"_"+str(spawncount)

		
		if newspawn:
			anti_vibracion = chair_instance.anti_vibracion 
			sin_gravedad = chair_instance.sin_gravedad 
			size = chair_instance.size
		chair_instance.anti_vibracion = anti_vibracion
		chair_instance.sin_gravedad = sin_gravedad
		chair_instance.size = size
		add_child(chair_instance)
		chair_instance.position = Vector3.ZERO
		chair_instance.rotation = Vector3.ZERO
		spawncount+=1


func _on_spawn_timer_timeout():
	spawn_chair()
	check_timer.start()


func _on_check_timer_timeout():
	if !is_instance_valid(chair_instance):
		respawn()
		return

	if !chair_instance.is_inside_tree():
		respawn()
		return
	
	if is_ancestor_of(chair_instance):
		check_timer.start()
		return
	
	var current_node = chair_instance
	var player_found = false
	while current_node:
		if player_group in current_node.get_groups():
			player_found = true
			break
		current_node = current_node.get_parent()
		
	# chair.get_tree().get_nodes_in_group("balls")  

	if !player_found:
		respawn()
		return
	
	if max_living_spawns > current_spawns:
		spawn_timer.start()
		current_spawns+=1
		print("respawn")
	else:
		check_timer.start()
		

func respawn():
	queue_free_chair()
	check_timer.stop()
	spawn_timer.start()

func queue_free_chair():
	if chair_instance && chair_instance.has_method("queue_free"):
		chair_instance.queue_free()
