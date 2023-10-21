extends Camera3D

var player
var camera_offset = Vector3(0, 2, -5)
var camera_speed = 5.0

func _ready():
	player = $"../Player"  # Asegúrate de que la ruta al jugador sea correcta

func _process(delta):
	if player:
		var target_position = player.global_transform.origin + camera_offset
		global_transform.origin = global_transform.origin.lerp(target_position, delta * camera_speed)
		look_at(player.global_transform.origin, Vector3(0, 1, 0))
