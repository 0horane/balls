extends "res://ObjectScenes/scripts/Liftable.gd"


var respawn_timer: Timer
const RESPAWN_TIME: float = 5.0  # Tiempo en segundos antes de reaparecer
const SHOOT_INTERVAL: float = 0.5  # Intervalo entre disparos en segundos
var Bullet := load("res://ObjectScenes/bullet.tscn")
var can_shoot: bool = true  # Controla la velocidad de disparo

func _ready():
	super()
	respawn_timer = Timer.new()
	respawn_timer.one_shot = true
	respawn_timer.wait_time = RESPAWN_TIME
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	add_child(respawn_timer)


func shoot():
	
	# Crea la bala
	var bullet_instance = Bullet.instantiate()
	# Agrega la bala como hijo de Main (ajusta según tu jerarquía)

	bullet_instance.global_position = global_position
	bullet_instance.global_rotation = global_rotation#global_transform.basis.get_euler()
	get_node("/root/Main").add_child(bullet_instance)
	bullet_instance.global_position = global_position
	bullet_instance.global_position += bullet_instance.transform.basis.z * 0.2 
	bullet_instance.global_rotation = global_rotation
	#bullet_instance.set_gravity_scale(0)  # Desactiva la gravedad para la bala

	#bullet_instance.set_friction(0.0)  # Desactiva la fricción


	# Después de disparar, comienza el tiempo de reaparición

	respawn_timer.start()


func _on_respawn_timer_timeout():
	if can_shoot:
		shoot()
		print("shot")
	#bullets_fired = 0
	
func add_to_parent(initpos, initrot):
	super(initpos, initrot)
	respawn_timer.start(1)
	can_shoot = true
	
func remove_from_parent(initpos, initrot):
	super(initpos, initrot)
	respawn_timer.stop()
	can_shoot = false
	
