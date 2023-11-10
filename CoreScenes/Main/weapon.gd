extends Node3D

var respawn_timer: Timer
const RESPAWN_TIME: float = 5.0  # Tiempo en segundos antes de reaparecer
const SHOOT_INTERVAL: float = 0.5  # Intervalo entre disparos en segundos

var can_shoot: bool = true  # Controla la velocidad de disparo

func _ready():
	respawn_timer = Timer.new()
	respawn_timer.one_shot = true
	respawn_timer.wait_time = RESPAWN_TIME
	respawn_timer.timeou.connect(_on_respawn_timer_timeout)
	add_child(respawn_timer)


func shoot():
	if can_shoot:
		# Crea la bala
		var bullet_instance = Bullet.instance()
		bullet_instance.global_position = global_transform.origin
		bullet_instance.global_rotation = global_transform.basis.get_euler()
		bullet_instance.set_gravity_scale(0)  # Desactiva la gravedad para la bala
		bullet_instance.set_friction(0.0)  # Desactiva la fricción

		# Agrega la bala como hijo de Main (ajusta según tu jerarquía)
		get_node("/root/Main").add_child(bullet_instance)

		# Después de disparar, comienza el tiempo de reaparición
		can_shoot = false
		respawn_timer.start()


func _on_respawn_timer_timeout():
	can_shoot = true
	respawn_timer.stop()
	bullets_fired = 0
