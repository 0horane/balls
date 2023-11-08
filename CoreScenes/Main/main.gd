extends Node


# Called when the node enters the scene tree for the first time.
func _ready():

	for x in range(0, 100):
		var chairloader = load("res://ObjectScenes/chair.tscn")
		var chair = chairloader.instantiate()
		chair.size=randf_range(0,1)**2+0.2
		add_child(chair)
		chair.global_position.x=randf_range(-20,20)
		chair.global_position.z=randf_range(-20,20)
		chair.mass=chair.size**3 *1000
		# chair. = randf_range(-PI / 4, PI / 4)

	var index = 0 



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
