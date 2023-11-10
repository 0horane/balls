@tool
extends RigidBody3D
@export var size:float=1 
var parentPos=Vector3.ZERO
var parentRot=Vector3.ZERO
var real_gravity_scale := gravity_scale

@onready var parenttest = get_parent()
@onready var parenttest2 = null


func _ready():
	$CollisionShape3D.transform = $CollisionShape3D.transform.scaled(Vector3(size,size,size))
	$MeshInstance3D.transform = $MeshInstance3D.transform.scaled(Vector3(size,size,size))
	



func _process(_delta):
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
	
func remove_from_parent(initpos, initrot, new_collison_shape):
	add_child(new_collison_shape)	
	
	global_position = initpos
	global_rotation = initrot
	gravity_scale = real_gravity_scale/5
	parentPos=null
	parentRot=null
	print(global_position, global_rotation, self)




