@tool
extends RigidBody3D

@export var size:float=1 
var volume:float 

@export var sin_gravedad := false
@export var anti_vibracion := false
var parentPos=Vector3.ZERO
var parentRot=Vector3.ZERO
var real_gravity_scale := gravity_scale

# ver https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html#introduction
# https://docs.godotengine.org/en/3.4/tutorials/shaders/your_first_shader/your_first_3d_shader.html?highlight=Vertel%20displacement#your-first-3d-shader

@onready var parenttest = get_parent()
@onready var parenttest2 = null


func _ready():
	$CollisionShape3D.transform = $CollisionShape3D.transform.scaled(Vector3(size,size,size))
	$MeshInstance3D.transform = $MeshInstance3D.transform.scaled(Vector3(size,size,size))
	contact_monitor=true
	max_contacts_reported=20
	if sin_gravedad:
		gravity_scale=0
		freeze=true
	else: 
		pass#gravity_scale=ProjectSettings.get_setting("physics/3d/default_gravity")
	




func _process(delta):

	
		
		
	if Engine.is_editor_hint():
		var parent  = get_parent()
		if parent.is_in_group("liftable_spawner") && (position != Vector3.ZERO || rotation != Vector3.ZERO || size != parent.size || sin_gravedad != parent.sin_gravedad || anti_vibracion != parent.anti_vibracion ):
			parent.global_position = global_position
			parent.global_rotation = global_rotation
			parent.sin_gravedad = sin_gravedad
			parent.anti_vibracion = anti_vibracion
			parent.size = size
			position=Vector3.ZERO
	else:
		if parentPos:
			rotation=parentRot
			position=parentPos
		elif sin_gravedad:
			pass # para que no entre en el de vibracion
		elif anti_vibracion:
			freeze = false 
			if linear_velocity.length() < 0.2 && angular_velocity.length() < PI/128:
				for node in get_colliding_bodies():
					if node.global_position.y < global_position.y:
						freeze=true
						break

					
				
			

func add_to_parent(initpos, initrot):
	for node in get_colliding_bodies():
		if "anti_vibracion" in node and !node.sin_gravedad:
			node.freeze=false
	global_position=initpos
	global_rotation=initrot
	gravity_scale=0
	parentPos=position
	parentRot=rotation
	
func remove_from_parent(initpos, initrot, new_collison_shape, vel):
	add_child(new_collison_shape)	
	
	global_position = initpos
	global_rotation = initrot
	gravity_scale = real_gravity_scale
	parentPos=null
	parentRot=null
	linear_velocity = vel*10




