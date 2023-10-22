extends RigidBody3D


const SPEED = 800.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var size=1
var realRotation:float = 0
var movementRotation:float = 0


var linear_velocity_before_collision:Vector3=linear_velocity

func _ready():
	contact_monitor=true
	max_contacts_reported=9999


func is_on_floor():
	return true #TODO

func _physics_process(delta):
	linear_velocity_before_collision=linear_velocity # to prevent collisions from causing jumps TODO rename
	
	# Horrendously cursed camera and direction system, took me 2 hours to debug,
	# stay away for your own sanity
	# Calculates the rotation of the ball's movement relative to the z axis, 
	# Then adjusts "movement rotation" (a delayed inerpolated version of the
	# angle, for smoother camera movements) in the equivalent of a .lerp
	# function but circular, given that angles loop back around.
	var horizontal_velocity = linear_velocity
	horizontal_velocity.y=0
	if horizontal_velocity.length()>0.1:
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
	# As good practice, you should replace UI actions with custom gameplay actions. //wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwaTODO
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var accelerometerValue = Input.get_accelerometer();
	accelerometerValue.rotated(transform.basis.y, PI/2)
	
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	if direction:
		angular_velocity = Vector3(-direction.z+accelerometerValue.z, 0, direction.x+accelerometerValue.y/32) \
			.rotated(Vector3(0,1,0),movementRotation) * SPEED*delta
	else:
		angular_velocity.x = move_toward(angular_velocity.x, 0, SPEED/100*delta)
		angular_velocity.z = move_toward(angular_velocity.z, 0, SPEED/100*delta)
		




func _on_body_entered(body):
	if "size" in body and size>body.size*4:
		var parent = body.get_parent()
		if parent:
			if parent!=self:				
				var pos=body.global_position
				var rot=body.global_rotation
				parent.remove_child(body)
				add_child(body)
				body.add_to_parent(pos, rot)
				linear_velocity=linear_velocity_before_collision
				change_size(body.size/12)
				
func change_size(addedsize):
	size+=addedsize
	$CollisionShape3D.shape.radius=size/2
	
