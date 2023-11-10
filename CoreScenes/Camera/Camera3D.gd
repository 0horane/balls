extends Camera3D

var player
var camera_offset
var camera_speed = 2.0

func _ready():
	#player = $"../Player"  
	player = $"../../Main".get_node(str(multiplayer.get_unique_id())) 


# https://www.youtube.com/watch?v=u2sX8UhGkoQ
# Aca esta un video de como era el katamari móvil con acelerometro
# No te dejaba ir para atrás, para no causar problemas de cámara como tenemos ahora, sino que te 
# permitía dar una vuelta total mirando para atrás. Podríamos replicarlo creo.

# Ademas, hay que hacer que la camara siga a una altura y distancia constante de la esfera según 
# tamaño. Sin tener en cuenta la altura variable casi no vibraría, me parece.  
func _process(delta):
	if is_instance_valid(player):
		camera_offset = Vector3(0, 2, -5).rotated(Vector3(0,1,0), player.movementRotation)
		var target_position = player.global_transform.origin + camera_offset
		global_transform.origin = global_transform.origin.lerp(target_position, delta * camera_speed)
		look_at(player.global_transform.origin, Vector3(0, 1, 0))
	else:
		player = $"../../Main".get_node(str(multiplayer.get_unique_id()))
		
