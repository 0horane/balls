extends RigidBody3D

const SPEED: float = 1000.0  # Velocidad de la bala

func _ready():
	linear_velocity = Vector3(0, 0, SPEED)
