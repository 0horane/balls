extends RigidBody3D

var SPEED: float = 10.0  # Velocidad de la bala
var DAMAGE: int = 20  # Velocidad de la bala
var BULLET_LIFETIME: float = 5.0  # Tiempo de vida de la bala en segundos
var DADDY: Node3D

var despawn_timer: Timer

func _ready():
	contact_monitor=true
	max_contacts_reported=1
	despawn_timer = Timer.new()
	despawn_timer.one_shot = true
	despawn_timer.wait_time = BULLET_LIFETIME
	despawn_timer.timeout.connect(_on_bullet_timeout)
	add_child(despawn_timer)
	# Inicia el temporizador cuando la bala es creada
	despawn_timer.start()

func _process(delta):
	global_position += transform.basis.z * SPEED * delta


func _on_bullet_timeout():
	print("eliminado")
	queue_free()
	


func _on_body_entered(body):
	if "health" in body:
		if body!=DADDY:
			body.take_damage(DAMAGE)
	print("emiminado")
	queue_free()
	
