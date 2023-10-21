extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var size=0.5

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var accelerometerValue = Input.get_accelerometer();
	accelerometerValue.rotated(transform.basis.y, PI/2)
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = (direction.x+accelerometerValue.y) * SPEED
		velocity.z = (direction.z+accelerometerValue.z) * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	for index in range(get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)

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

	move_and_slide()


	

