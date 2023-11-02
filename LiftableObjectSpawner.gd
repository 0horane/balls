extends Marker3D
@export var size:float=1

@export var chair_scene : PackedScene = preload("res://chair.tscn")
var chair_instance : Node
var spawn_timer : Timer
var check_timer : Timer
var player_group : String = "balls"
var replacement_timer_duration : float = 5

func _ready():
	spawn_timer = Timer.new()
	check_timer = Timer.new()
func setup_timers():

	spawn_timer.wait_time = 10
	check_timer.wait_time = 5

	spawn_timer.one_shot = true
	check_timer.one_shot = true

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	check_timer.timeout.connect(_on_check_timer_timeout)

	#spawn_timer.start()
	check_timer.start()
	spawn_chair()
	
func spawn_chair():
	if chair_scene:
		chair_instance = chair_scene.instance()
		if chair_instance.has_method("set_size"):
			chair_instance.set_size(size)
		#chair_scene.size= size
		queue_free_chair()
		add_child(chair_instance)
		spawn_timer.start()

func _on_spawn_timer_timeout():
	spawn_chair()
	spawn_timer.start()

func _on_check_timer_timeout():
	if !chair_instance:
		
		return

	if !chair_instance.is_inside_tree():
		spawn_timer.wait_time = replacement_timer_duration
		spawn_timer.start()
		check_timer.stop()
	else:
		var current_node = chair_instance
		var player_found = false
		while current_node:
			if player_group in current_node.get_groups():
				player_found = true
				break
			current_node = current_node.get_parent()

		if !player_found:
			spawn_timer.wait_time = replacement_timer_duration
			spawn_timer.start()
			check_timer.start()

func queue_free_chair():
	if chair_instance:
		chair_instance.queue_free()
