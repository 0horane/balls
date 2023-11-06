@tool
extends RigidBody3D

@export var size:float=1 

@export var is_static := false
var parentPos=Vector3.ZERO
var parentRot=Vector3.ZERO


@onready var parenttest = get_parent()
@onready var parenttest2 = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$CollisionShape3D.transform = $CollisionShape3D.transform.scaled(Vector3(size,size,size))
	$MeshInstance3D.transform = $MeshInstance3D.transform.scaled(Vector3(size,size,size))
	contact_monitor=true
	max_contacts_reported=20
	

# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta):

			
		
		
	if Engine.is_editor_hint():
		var parent  = get_parent()
		if parent.is_in_group("liftable_spawner") && (position != Vector3.ZERO || rotation != Vector3.ZERO || size != parent.size):
			parent.global_position = global_position
			parent.global_rotation = global_rotation
			parent.size = size
			position=Vector3.ZERO
	else:
		if parentPos:
			rotation=parentRot
			position=parentPos
		elif !is_static:
			freeze = false 
			if linear_velocity.length() < 0.2 && angular_velocity.length() < PI/128:
				for node in get_colliding_bodies():
					if node.global_position.y < global_position.y:
						freeze=true
						break
			elif name=="eitan":
				if linear_velocity.length() < 0.2:
					print("TOO MUCH MOVEMENT")
				else:
					print("TOO MUCH ROT", PI/32)
					
				
			

func add_to_parent(initpos, initrot):
	for node in get_colliding_bodies():
		if "is_static" in node:
			node.freeze=false
	global_position=initpos
	global_rotation=initrot
	gravity_scale=0
	parentPos=position
	parentRot=rotation
	

	#$CollisionShape3D.queue_free()


