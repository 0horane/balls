extends RigidBody3D

var health: int = 100

#### Variables para física	
const SPEED := 1000.0
const JUMP_VELOCITY := 4.5
const USE_SIMPLIFIED_COLLISION_MESH := true

#### variables para Absorcion
const MINIMUM_ABSORBTION_RATIO:float = 1.0/2**3
const MINIMUM_PLAYER_ABSORBTION_RATIO:float=0.75
var size :float = 1000
@onready var volume :float = 4.0/3*PI*$MeshInstance3D.mesh.radius**3
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


#### variables para camara
var realRotation:float = 0
var movementRotation:float = 0

#### Variables para multijuagdor
var syncPos:Vector3
var syncRot:Quaternion
var username = ""


var linear_velocity_before_collision := linear_velocity

func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	gravity_scale=70/ProjectSettings.get_setting("physics/3d/default_gravity")
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		contact_monitor=true
		max_contacts_reported=9999
	$Label3D.text = username
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, $MeshInstance3D.get_mesh().get_mesh_arrays())



func is_on_floor():
	return true #TODO



	

func _physics_process(delta):
	if not $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		global_position = lerp(global_position, syncPos, 0.5)
		var newRot:=Quaternion(transform.basis).slerp(syncRot, 0.5)
		transform.basis = Basis(newRot)
		return

	RenderingServer.global_shader_parameter_set("player_pos", position)
	
	syncPos = global_position
	syncRot = Quaternion(transform.basis)
		
	if linear_velocity.y>5:
		linear_velocity.y=5
	
	linear_velocity_before_collision=linear_velocity # to prevent collisions from causing jumps TODO rename
	
	if Input.is_action_pressed("kill_self_debug"):
		on_death()
	
	#$Label3D.global_position = global_position
	$Label3D.global_rotation += Vector3.ZERO 	
	$Label3D.position.y =  (volume/4.0*3/PI)**(1.0/3)*1.8
	

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
	direction += Vector3(accelerometerValue.y/8 + (PI/2.5 if accelerometerValue.y else 0), 0 ,  accelerometerValue.x/8 ) #accelerometerValue.y

	if direction:
		# the possibilites here is to 
		# 1) have an apply_central_force and then to calculate needed angular velocity based on 
		# that (because rigidbody rotation only seems to be correctly calculated from spheres), 
		# 2) to set the torque (angular_velocity =), 
		# 3) to add to the torque (apply_torque),  
		#
		# The second one is currently being used, some previous ones are in git history
		
		#the current method
		angular_velocity = direction.rotated(Vector3(0,1,0),movementRotation) * SPEED*delta  *  1/pow(3*volume/(4*PI), 1/3.0)/2 # is this even teh right formula
	else:
		angular_velocity.x = move_toward(angular_velocity.x, 0, SPEED/100*delta)
		angular_velocity.z = move_toward(angular_velocity.z, 0, SPEED/100*delta)

		
		



# Lo que faltaria hacer:
# - Cambiar la manera que se hace el scale de los vectores para considerar 3 dimensiones/rotacion
#   (por ahora conviene no rotar y solo escalar proporcionalmente)
# - Usar mas que un punto, tipo encontrar 8 4 que queden por dentro y usar esos
# - uso de centroide, rotando el negativo de  como indicaría aca:
#   https://www.euclideanspace.com/maths/geometry/rotations/conversions/eulerToAngle/index.htm
# - Subir fricción 
# - Evitar que esfera solo crezca en una dirección

func _on_body_entered(body):
	if body.is_in_group("balls") && volume*MINIMUM_PLAYER_ABSORBTION_RATIO>body.volume:
		body.on_death()
		linear_velocity = linear_velocity_before_collision
		return
	
	if "size" in body and volume*MINIMUM_ABSORBTION_RATIO>GameManager.find_body_volume(body):
		var parent = body.get_parent()
		if parent && parent!=self:
			absorb_body(body, body.name, body.global_position, body.global_rotation)
			linear_velocity = linear_velocity_before_collision
			

# Notas: de mis pruebas en el juego original, el hitbox del katamri se desforma solo en approx. el 
# centro del objeto original (en objetos largos era mas hacia la punta). Ademas, parece que el 
# hitbox de contacto en el piso y objetos grandes es mayor al hitbox que alica para levantar  
# objetos, que es mas chica. Lo que #TODO habría que hacer seria que el objeto solo sea levantado 
# despues de ciero volumen de intersección, pero sería bastante complicado.  
@rpc("any_peer")
func absorb_body(body, bname, globpos, globrot): #TODO rewrite to use relative posotions for cleaner multiplayer code
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		absorb_body.rpc(body, body.name, globpos, globrot)
	else:
		if "object_id" in body:
			body = instance_from_id(body.object_id )
		if !body || !is_instance_valid(body):
			body = find_child2(get_tree().root, bname)
		global_position = syncPos
		transform.basis = Basis(syncRot)

	var pos=globpos
	var rot=globrot
	var parent = body.get_parent()
	
	if not $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		global_position = lerp(global_position, syncPos, 0.5)
		var newRot:=Quaternion(transform.basis).slerp(syncRot, 0.5)
		transform.basis = Basis(newRot)
	
	# adds object as player child
	parent.remove_child(body)
	add_child(body)
	body.add_to_parent(pos, rot)
	
	# removes child object hitbox
	# child collisionObject will have to be regenerated or added from lifted_object_map
	var body_collision_shape : CollisionShape3D = body.get_node("CollisionShape3D")
	lifted_object_map[body] = body_collision_shape
	body.remove_child(body_collision_shape)
	
	
	
	call_deferred("morph_shape", body)
	call_deferred("change_size", body)

	print(volume)
	
		
	



func change_size(body: Node3D):
	size+=body.size/12
	print(volume," ", GameManager.find_body_volume(body))
	#print(body.size)
	volume += GameManager.find_body_volume(body)

	#volume=get_mesh_volume(mesh)
	

func morph_shape(body):
	# child centroid. as seen by the code, im not actually bothering to calcuate the centroid. 
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
	mdt.set_vertex(closest_aligned_vertex, object_centroid_from_player_center.project(mdt.get_vertex(closest_aligned_vertex)))
	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
	
	var mi = MeshInstance3D.new()
	mi.mesh = mesh

	mi.create_convex_collision(true, USE_SIMPLIFIED_COLLISION_MESH)
	var new_collison_shape :Shape3D = find_child2(mi,"CollisionShape3D").shape
	$CollisionShape3D.shape = new_collison_shape
	mi.queue_free()
	#TODO queue_free, leak de memoria
	
	
func find_child2(node, nam):
	var returnbody = null
	for body in node.get_children():
		if nam in body.name:
			return body
		else: 
			returnbody = find_child2(body, nam) 
			if returnbody:
				return returnbody
	return null
			
func prchldrec(bdy, init=""):
	print(init, bdy)
	for body in bdy.get_children():
		prchldrec(body, init+" ")


@rpc("any_peer" )
func on_death():
	for child in get_children():
		if "size" in child:
			var pos = child.global_position
			var rot = child.global_rotation
			var vel = child.global_position - global_position
			remove_child(child)
			get_parent().add_child(child)
			child.call_deferred("remove_from_parent", pos, rot, lifted_object_map[child], vel)
	
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		get_parent().get_node("CanvasLayer").show()
		get_parent().get_node("CanvasLayer/Control/LineEdit").text = username
		on_death.rpc()
		
	print(multiplayer.get_unique_id(), " detected deah of ", name)
	
	queue_free()
			




func take_damage(amount:int):
	health-=amount
	if health<0:
		on_death()
		
		
static func recurse_find(node:Node, bname:String):
	if bname.split("_")[0].substr(1) in node.name:
		node.print_tree_pretty()
	else:
		for child in node.get_children():
			recurse_find(child, bname)
	

