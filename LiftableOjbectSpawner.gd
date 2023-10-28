extends Marker3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var chairloader = load("res://chair.tscn")
	var chair = chairloader.instantiate()
	add_child(chair)
	chair.position.x = 0
	chair.position.z = 0
	chair.position.y = 0
	if chair.get_parent() != self and chair.get_tree().get_nodes_in_group("balls") :
		print("hola")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
