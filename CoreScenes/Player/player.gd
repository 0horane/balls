extends RigidBody3D


const SPEED := 600.0
const JUMP_VELOCITY := 4.5
const USE_SIMPLIFIED_COLLISION_MESH := false
const MINIMUM_ABSORBTION_RATIO:float=0.25

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var size :float = 1
var realRotation:float = 0
var movementRotation:float = 0
var lifted_object_map := {} # aactualmente mapea Body->Collisionshape. Actualizar si algo se cambia
var mesh:=ArrayMesh.new()


var linear_velocity_before_collision := linear_velocity

func _ready():
	contact_monitor=true
	max_contacts_reported=9999
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, $MeshInstance3D.get_mesh().get_mesh_arrays())
	$MeshInstance3D.hide()


func is_on_floor():
	return true #TODO

func _physics_process(delta):
	
	if linear_velocity.y>5:
		linear_velocity.y=5
	
	linear_velocity_before_collision=linear_velocity # to prevent collisions from causing jumps TODO rename
	

	
	# Horrendously cursed camera and direction system, took me 2 hours to debug,
	# stay away for your own sanity
	# Calculates the rotation of the ball's movement relative to the z axis, 
	# Then adjusts "movement rotation" (a delayed inerpolated version of the
	# angle, for smoother camera movements) in the equivalent of a .lerp
	# function but circular, given that angles loop back around.
	var horizontal_velocity := linear_velocity
	horizontal_velocity.y=0
	if horizontal_velocity.length()>0.1:
		realRotation = Vector3(0,0,1).signed_angle_to(horizontal_velocity, Vector3(0,1,0))
		var rotation_frac :float= delta*1
		#if abs(movementRotation)+abs(realRotation)>PI: 
		if abs(movementRotation-realRotation)<PI: 
			movementRotation = (1-rotation_frac)*movementRotation  +  rotation_frac*realRotation
		else:
			movementRotation = (1-rotation_frac)*movementRotation  +  rotation_frac * (2*PI - abs(realRotation))*sign(movementRotation)
		if movementRotation > PI:
			movementRotation-=2*PI
		if movementRotation < -PI:
			movementRotation+=2*PI
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		linear_velocity.y = JUMP_VELOCITY
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions. //wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwaTODO
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var accelerometerValue := Input.get_accelerometer();
	accelerometerValue.rotated(transform.basis.y, PI/2)
	
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
	if direction:
		# the possibilites here is to 
		# 1) have an apply_central_force and then to calculate needed angular velocity based on 
		# that (because rigidbody rotation only seems to be correctly calculated from spheres), 
		# 2) to set the torque (angular_velocity =), 
		# 3) to add to the torque (apply_torque),  
		#
		# The second one is currently being used, some previous ones are in git history
		
		#the current method
		angular_velocity = Vector3(-direction.z+accelerometerValue.z, 0, direction.x+accelerometerValue.y/32) \
			.rotated(Vector3(0,1,0),movementRotation) * SPEED*delta
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
	if "size" in body and size*MINIMUM_ABSORBTION_RATIO>body.size:
		var parent = body.get_parent()

		if parent && parent!=self:
			absorb_body(body)

# Notas: de mis pruebas en el juego original, el hitbox del katamri se desforma solo en approx. el 
# centro del objeto original. Ademas, parece que el hitbox de contacto en el piso y objetos grandes 
# es mayor al hitbox que alica para levantar objetos, que es mas chica. 
func absorb_body(body):
	var pos=body.global_position
	var rot=body.global_rotation
	var parent = body.get_parent()
	
	# adds object as player child
	parent.remove_child(body)
	add_child(body)
	body.add_to_parent(pos, rot)
	#linear_velocity=linear_velocity_before_collision
	change_size(body.size/12)
	
	
	# removes child object hitbox
	# child collisionObject will have to be regenerated or added from lifted_object_map
	var body_collision_shape : CollisionShape3D = body.get_node("CollisionShape3D")
	lifted_object_map[body] = body_collision_shape
	body.remove_child(body_collision_shape)
	
	# child centroid 
	var centroid := get_centroid(body.get_node("MeshInstance3D").get_mesh().get_faces(), body.size*scale_to_factor(body.get_node("MeshInstance3D").scale))
	print(centroid.length())
	var object_centroid_from_player_center:Vector3 = body.position
	
	

	# this section modifies the mesh to extend the best aligned point to the centroid and set its
	# Position there. This is enough when a conevex mesh is then generated by the engine. 
	# The centroid must first be adjusted by rotating it by the negative of the angle of the player,
	# keeping it at the same distance
	var mdt := MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	var closest_aligned_vertex:= 0
	var closest_angle:float=999
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
