@tool
extends Marker3D
@export var size:float=1

@export var chair_scene : PackedScene = preload("res://chair.tscn")
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
	spawn_chair()
	
	
func setup_timers():

	spawn_timer.wait_time = 2 # change to 30 later
	check_timer.wait_time = 5

	spawn_timer.one_shot = true
	check_timer.one_shot = true

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	check_timer.timeout.connect(_on_check_timer_timeout)
	
	add_child(spawn_timer)
	add_child(check_timer)
	
	check_timer.start()
	
func spawn_chair():
	if chair_scene:
		print("spawning_chair")
		chair_instance = chair_scene.instantiate()
		chair_instance.size = size
		add_child(chair_instance)
		chair_instance.position = Vector3.ZERO
		chair_instance.rotation = Vector3.ZERO


func _on_spawn_timer_timeout():
	spawn_chair()
	check_timer.start()


func _on_check_timer_timeout():
	if !is_instance_valid(chair_instance):
		respawn()
		print("isnt valid")
		return

	if !chair_instance.is_inside_tree():
		respawn()
		print("isnt inside tree")
		return
	
	if is_ancestor_of(chair_instance):
		print("is ancestor")
		check_timer.start()
		return
	
	var current_node = chair_instance
	var player_found = false
	while current_node:
		if player_group in current_node.get_groups():
			print(current_node.get_groups())
			player_found = true
			break
		current_node = current_node.get_parent()

	if !player_found:
		print("player not found")
		respawn()
		return
	
	print("nothing")
	check_timer.start()
		

func respawn():
	queue_free_chair()
	check_timer.stop()
	spawn_timer.start()

func queue_free_chair():
	if chair_instance && is_instance_valid(chair_instance):
		chair_instance.queue_free()
