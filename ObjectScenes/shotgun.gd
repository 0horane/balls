@tool
extends "res://ObjectScenes/scripts/armas.gd"


# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	RESPAWN_TIME  = 3
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)
	pass


func _on_respawn_timer_timeout():
	if can_shoot:
		for x in range(10):
			shoot()
	#bullets_fired = 0
	
func shoot():
	
	# Crea la bala
	var bullet_instance = Bullet.instantiate()
	# Agrega la bala como hijo de Main 	

	bullet_instance.global_position = global_position
	bullet_instance.global_rotation = global_rotation#global_transform.basis.get_euler()
	bullet_instance.BULLET_LIFETIME=0.5
	bullet_instance.DAMAGE=10
	get_node("/root/Main").add_child(bullet_instance)
	bullet_instance.global_position = global_position
	bullet_instance.global_position += bullet_instance.transform.basis.z * 1*size
	bullet_instance.global_rotation = global_rotation + Vector3(randfn(0,0.1),randfn(0,0.1),randfn(0,0.1))
	
	
	bullet_instance.DADDY = get_parent()


	# Después de disparar, comienza el tiempo de reaparición

	respawn_timer.start()
