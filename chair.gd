extends RigidBody3D
@export var size:float=1 
var parentPos=Vector3.ZERO
var parentRot=Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	$CollisionShape3D.transform = $CollisionShape3D.transform.scaled(Vector3(size,size,size))
	$ChairSds2.transform = $ChairSds2.transform.scaled(Vector3(size,size,size))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#if size<0.5:
		#print( snapped(position, Vector3.ONE*0.01))
		#pass
	if parentPos:
		rotation=parentRot
		position=parentPos
		#pass
	

func add_to_parent(initpos, initrot):
	global_position=initpos
	global_rotation=initrot
	gravity_scale=0
	parentPos=position
	parentRot=rotation
	$CollisionShape3D.queue_free()

