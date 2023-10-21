extends RigidBody3D


const SPEED = 800.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var size=0.5
var realRotation:float = 0
var movementRotation:float = 0

func is_on_floor():
	return true #TODO

func _physics_process(delta):
	
	# Horrendously cursed camera and direction system, took me 2 hours to debug,
	# stay away for your own sanity
	# Calculates the rotation of the ball's movement relative to the z axis, 
	# Then adjusts "movement rotation" (a delayed inerpolated version of the
	# angle, for smoother camera movements) in the equivalent of a .lerp
	# function but circular, given that angles loop back around.
	if linear_velocity.length()>0.1:
		var horizontal_velocity = linear_velocity
		horizontal_velocity.y=0
		realRotation = Vector3(0,0,1).signed_angle_to(horizontal_velocity, Vector3(0,1,0))
		var rotation_frac = delta*1
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
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var accelerometerValue = Input.get_accelerometer();
	accelerometerValue.rotated(transform.basis.y, PI/2)
	
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	if direction:
		angular_velocity = Vector3(-direction.z+accelerometerValue.z, 0, direction.x+accelerometerValue.y/32) \
			.rotated(Vector3(0,1,0),movementRotation) * SPEED*delta
	else:
		angular_velocity.x = move_toward(angular_velocity.x, 0, SPEED*delta)
		angular_velocity.z = move_toward(angular_velocity.z, 0, SPEED*delta)
		
	for collision in get_colliding_bodies():
		# We get one of the collisions with the player

		# If the collision is with ground
		#if collision.get_collider() == null:
		#	continue

		# If the collider is with a mob
		if collision.get_collider().is_in_group("object") && collision.get_collider().size < size*5:
			var mob = collision.get_collider()
			# we check that we are hitting it from above.
			#if Vector3.UP.dot(collision.get_normal()) > 0.1:
				# If so, we squash it and bounce.
				#mob.squash()
				#target_velocity.y = bounce_impulse

