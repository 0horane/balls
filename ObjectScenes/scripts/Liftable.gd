@tool
extends RigidBody3D
@export var size:float=1 
var parentPos=Vector3.ZERO
var parentRot=Vector3.ZERO
var real_gravity_scale := gravity_scale

@onready var parenttest = get_parent()
@onready var parenttest2 = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$CollisionShape3D.transform = $CollisionShape3D.transform.scaled(Vector3(size,size,size))
	$MeshInstance3D.transform = $MeshInstance3D.transform.scaled(Vector3(size,size,size))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.

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
	
func remove_from_parent(initpos, initrot):
	$MeshInstance3D.create_convex_collision(true, true)
	var new_collison_shape :CollisionShape3D = $MeshInstance3D.find_child("CollisionShape3D")
	new_collison_shape.scale = $MeshInstance3D.scale
	new_collison_shape.rotation = $MeshInstance3D.rotation
	new_collison_shape.position = $MeshInstance3D.position
	$MeshInstance3D.get_child(0).remove_child(new_collison_shape)
	add_child(new_collison_shape)
	$MeshInstance3D.get_child(0).queue_free()
	
	global_position = initpos
	global_rotation = initrot
	gravity_scale = real_gravity_scale/5
	parentPos=null
	parentRot=null
	print(global_position, global_rotation, self)




