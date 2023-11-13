extends CharacterBody3D

const SPEED: float = 10.0  # Velocidad de la bala
const BULLET_LIFETIME: float = 5.0  # Tiempo de vida de la bala en segundos

var despawn_timer: Timer

func _ready():
	despawn_timer = Timer.new()
	despawn_timer.one_shot = true
	despawn_timer.wait_time = BULLET_LIFETIME
	despawn_timer.timeout.connect(_on_bullet_timeout)
	add_child(despawn_timer)

func _process(delta):
	global_position += transform.basis.z * SPEED * delta

	# Inicia el temporizador cuando la bala es creada
	despawn_timer.start()

func _on_bullet_timeout():
	queue_free()
