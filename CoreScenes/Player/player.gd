extends RigidBody3D

var health: int = 100

#### Variables para física	
const SPEED := 600.0
const JUMP_VELOCITY := 4.5
const USE_SIMPLIFIED_COLLISION_MESH := true

#### variables para Absorcion
const MINIMUM_ABSORBTION_RATIO:float=0.25
const MINIMUM_PLAYER_ABSORBTION_RATIO:float=0.75
var size :float = 10
var lifted_object_map := {} # aactualmente mapea Body->Collisionshape. Actualizar si algo se cambia
var mesh:=ArrayMesh.new()

#var target_player:= Player 

#### Variables para el sistema de armas
#var can_shoot := false
#var shots_fired := 0
#var max_shots := 10
#var current_weapon: Weapon
#var glock: Weapon  # Referencia a la Glock
#var subfusil: Weapon  # Referencia al Subfusil

# No se para que era esto. puede que para que tenga mas gravedad la esfera que otros cuerpos?
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#### variables para camara
var realRotation:float = 0
var movementRotation:float = 0

#### Variables para multijuagdor
var syncPos:Vector3
var syncRot:Quaternion


var linear_velocity_before_collision := linear_velocity

func _ready():
	contact_monitor=true
	max_contacts_reported=9999
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, $MeshInstance3D.get_mesh().get_mesh_arrays())
	#glock = $Glock
	#subfucil = $subfucil
	#current_weapon =   # Comienza con la Glock
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())



func is_on_floor():
	return true #TODO

func _physics_process(delta):
	if not $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		global_position = lerp(global_position, syncPos, 0.5)
		var newRot:=Quaternion(transform.basis).slerp(syncRot, 0.5)
		transform.basis = Basis(newRot)

		return
	
	syncPos = global_position
	syncRot = Quaternion(transform.basis)
		
	if linear_velocity.y>5:
		linear_velocity.y=5
	
	linear_velocity_before_collision=linear_velocity # to prevent collisions from causing jumps TODO rename
	
	if Input.is_action_pressed("kill_self_debug"):
		on_death()
	

	# Calculates the rotation of the ball's movement relative to the z axis, 
	# Then lerps "movement rotation" 
	var horizontal_velocity := linear_velocity
	horizontal_velocity.y=0
	if horizontal_velocity.length()>0.1:
		realRotation = Vector3(0,0,1).signed_angle_to(horizontal_velocity, Vector3(0,1,0))
		movementRotation = lerp_angle(movementRotation, realRotation, delta)
		
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		linear_velocity.y = JUMP_VELOCITY
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions. //wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwaTODO
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var accelerometerValue := Input.get_accelerometer();
	accelerometerValue.rotated(transform.basis.y, PI/2)

	
	var direction := Vector3(-input_dir.y, 0, input_dir.x).normalized()
	direction += Vector3(accelerometerValue.y/5, 0 ,  accelerometerValue.x/5) #accelerometerValue.y

	if direction:
		# the possibilites here is to 
		# 1) have an apply_central_force and then to calculate needed angular velocity based on 
		# that (because rigidbody rotation only seems to be correctly calculated from spheres), 
		# 2) to set the torque (angular_velocity =), 
		# 3) to add to the torque (apply_torque),  
		#
		# The second one is currently being used, some previous ones are in git history
		
		#the current method
		angular_velocity = direction.rotated(Vector3(0,1,0),movementRotation) * SPEED*delta
	else:
		angular_velocity.x = move_toward(angular_velocity.x, 0, SPEED/100*delta)
		angular_velocity.z = move_toward(angular_velocity.z, 0, SPEED/100*delta)

		
		



# Lo que faltaria hacer:
# - Mejorar la camara que se mueve mucho
# - Cambiar la manera que se hace el scale de los vectores para considerar 3 dimensiones/rotacion
#   (por ahora conviene no rotar y solo escalar proporcionalmente)
# - usar proyección de vector sobre el mas cercano en evz de reemplazarlo
# - Usar mas que un punto, tipo encontrar 8 4 que queden por dentro y usar esos
# - uso de centroide, rotando el negativo de  como indicaría aca:
#   https://www.euclideanspace.com/maths/geometry/rotations/conversions/eulerToAngle/index.htm
# - Subir fricción 
# - Evitar que esfera solo crezca en una dirección

func _on_body_entered(body):
	#print("body entered: ", body)
	if body.is_in_group("balls") && size*MINIMUM_PLAYER_ABSORBTION_RATIO>body.size:
		body.on_death()
		return
	
	if "size" in body and size*MINIMUM_ABSORBTION_RATIO>body.size:
		var parent = body.get_parent()

		if parent && parent!=self:
			absorb_body(body)
			

# Notas: de mis pruebas en el juego original, el hitbox del katamri se desforma solo en approx. el 
# centro del objeto original (en objetos largos era mas hacia la punta). Ademas, parece que el 
# hitbox de contacto en el piso y objetos grandes es mayor al hitbox que alica para levantar  
# objetos, que es mas chica. Lo que #TODO habría que hacer seria que el objeto solo sea levantado 
# despues de ciero volumen de intersección, pero sería bastante complicado.  
@rpc("any_peer", "call_local" )
func absorb_body(body):
	var pos=body.global_position
	var rot=body.global_rotation
	var parent = body.get_parent()
	
	# adds object as player child
	parent.remove_child(body)
	add_child(body)
	body.add_to_parent(pos, rot)
	
	# esto es bastante arbitario e impreciso con cambios de tamaño. Hay que ver o de usar size^3 
	# como fuente del volumen, o si no intentar calcular el volumen, ya sea 1) usando tetraedros 
	# desde el centroide hasta los vertices (medio lento pero muy preciso, mejor solución
	# si tenemos la lista de triangulos en vez de vertices), 2) usando voxeles y un arbol octal de profunidad
	# variable donde se marcan y luego miden las intersecciones de cada vector, 3) tomar los 8 esquinas
	# de un cubo, encontrar el punto con un angulo mas similar, y calcular el volumen del cuboide 
	# rectangular con puntas opuestas en el centro y en ese punto, y sumar cada una 
	change_size(body.size/12)
	
	
	# removes child object hitbox
	# child collisionObject will have to be regenerated or added from lifted_object_map
	var body_collision_shape : CollisionShape3D = body.get_node("CollisionShape3D")
	lifted_object_map[body] = body_collision_shape
	body.remove_child(body_collision_shape)
	
	# child centroid. as seen by the code, im not actually bothering to calcuate the centroid. explained later
	var centroid := get_centroid(body.get_node("MeshInstance3D").get_mesh().get_faces(), body.size*scale_to_factor(body.get_node("MeshInstance3D").scale))
	var object_centroid_from_player_center:Vector3 = body.position
	
	

	# this section modifies the mesh to extend the best aligned point to the centroid and set its
	# Position there. This is enough when a conevex mesh is then generated by the engine. 
	# The centroid must first be adjusted by rotating it by the negative of the angle of the player,
	# keeping it at the same distance. Ideally this should use the centroid vector projected onto
	# the other one, to avoid large deformations, but with meshes as detailed as these it wont be 
	# relevant.  maybe do that later
	
	# also, the vulkan renderer is not compatible with meshdatatool on android, due to a bug in 
	# godot. the first bug i've encuntered so far. https://github.com/godotengine/godot/issues/75599
	# everything must be set to a gl_compatibility renderer because of this
	
	
	var mdt := MeshDataTool.new()
	print(mesh)
	mdt.create_from_surface(mesh, 0)
	var closest_aligned_vertex:= 0
	var closest_angle:float=999
	
	# the way this has to check the angle of every part of the mesh is incredibly inefficient. we 
	# should either offload this to another thread or reduce the vertex count of the sphere mesh.
	# ideally both. the second is already done.
	for i in range(mdt.get_vertex_count()):
		var vertex := mdt.get_vertex(i) # mdt.get_vertex_normal(i) # shoule be equivalent
		var current_angle := vertex.angle_to(object_centroid_from_player_center)
		if current_angle < closest_angle:
			closest_angle = current_angle
			closest_aligned_vertex = i
	mdt.set_vertex(closest_aligned_vertex, object_centroid_from_player_center)
	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
	# idk if we should be using the same mesh for calculations or a separate one
	# var mi = MeshInstance.new()
	# mi.mesh = mesh
	$MeshInstance3D.set_mesh(mesh)
	$MeshInstance3D.create_convex_collision(true, USE_SIMPLIFIED_COLLISION_MESH)
	var new_collison_shape :Shape3D = $MeshInstance3D.find_child("CollisionShape3D").shape
	$CollisionShape3D.shape = new_collison_shape
	$MeshInstance3D.remove_child($MeshInstance3D.get_child(0))

	#TODO queue_free, leak de memoria
	
	
	

	
	

# Esto no calcula verdadermante al centroide. habría que multiplicar cada uno por el area de los 
# triangulos vecinos, para que sea mucho mas preciso, ya que hay objetos con ams vertices en un lado
# que en otro. Mas simple que usar este método es centrar bien el objeto a ojo en la escena
func get_centroid(vertexList: PackedVector3Array, scale:float) -> Vector3:
	var avg:=Vector3.ZERO
	for vertex in vertexList:
		avg+=vertex
	return avg*scale/len(vertexList)
	
		
	
	

func change_size(addedsize):
	size+=addedsize
	#$CollisionShape3D.shape.radius=size/2
	
func scale_to_factor(scale:Vector3) -> float:
	# this is terrible and ideally i should be multiplying the scaled mesh vectors by whichever corresponds 
	# according to direction. it might be worth doing, depends #TODO
	return (scale.x + scale.y + scale.z) 

@rpc("any_peer", "call_local" )
func on_death():
	for child in get_children():
		if "size" in child:
			var pos = child.global_position
			var rot = child.global_rotation
			
			remove_child(child)
			get_parent().add_child(child)
			child.call_deferred("remove_from_parent", pos, rot, lifted_object_map[child])
			
	queue_free()
			
			
