extends RigidBody3D
@export var size:float=1 
var parentPos=Vector3.ZERO
var parentRot=Vector3.ZERO

@onready var parenttest = get_parent()
@onready var parenttest2 = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$CollisionShape3D.transform = $CollisionShape3D.transform.scaled(Vector3(size,size,size))
	$MeshInstance3D.transform = $MeshInstance3D.transform.scaled(Vector3(size,size,size))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

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
	print(position)
	#$CollisionShape3D.queue_free()

