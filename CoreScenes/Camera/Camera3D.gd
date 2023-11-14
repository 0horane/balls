extends Camera3D

var player
var camera_offset
var camera_speed = 2.0
var heightarray = range(60*5).map(func (n): return 0)
var ticks:int=0



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
	ticks+=1
	if is_instance_valid(player):
		var relative_distance_vector = Vector3(0, 2, -5)*pow(player.volume, 1.0/3)*1.4
		heightarray[ticks % len(heightarray)] = player.global_position.y
		var avgheight = heightarray.reduce(func (accum, number): return accum+number)/float(len(heightarray))
		var savedy = global_position.y
		camera_offset = relative_distance_vector.rotated(Vector3(0,1,0), player.movementRotation)
		var target_position = player.global_transform.origin + camera_offset
		
		global_transform.origin = global_transform.origin.lerp(target_position, delta * camera_speed)
		look_at(player.global_transform.origin, Vector3(0, 1, 0))
		global_position.y = lerp(savedy, avgheight+relative_distance_vector.y, 0.5) 
	else:
		player = $"../../Main".get_node(str(multiplayer.get_unique_id()))
		
