extends CharacterBody3D

const SPEED: float = 10.0  # Velocidad de la bala

func _ready():
	pass
	
func _process(delta):
	global_position+=(transform.basis.z * SPEED * delta)

