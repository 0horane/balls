extends Node

var Players = {}
var Liftables = {}
var thread: Thread
var mutex: Mutex
var bodylist := []

# The thread will start here.
func _ready():
	mutex = Mutex.new()
	thread = Thread.new()
	thread.start(_thread_function)


# Increment the value from the thread, too.
func _thread_function():
	while true:
		if bodylist:
			mutex.lock()
			var bodydata=bodylist.pop_front()
			mutex.unlock()
			calc_body_volume(bodydata["body"], bodydata["mesh"], bodydata["scale"])
			

func add_body_to_vol_queue(body:Node3D):
	mutex.lock()
	bodylist.append({
		"body":body, 
		"mesh":body.get_node("MeshInstance3D"),
		"scale":body.get_node("MeshInstance3D").scale
		})
	mutex.unlock()
			

static func find_body_volume(body:Node3D) -> float:
	if body.volume!=0:
		print("hit")
		return body.volume
	else:
		print("mi9ss")
		return calc_body_volume(body, body.get_node("MeshInstance3D"), body.get_node("MeshInstance3D").scale)
		
static func calc_body_volume(body:Node3D, bodymeshinstance: MeshInstance3D, scalebasis:Vector3):
	body.volume = get_mesh_volume(bodymeshinstance.mesh)*scalebasis.x*scalebasis.y*scalebasis.z
	return body.volume
		
# https://github.com/godotengine/godot-proposals/issues/2293#issuecomment-779374733
static func get_mesh_volume(mesh:Mesh):
	var vol=0
	var MDT=MeshDataTool.new()
	MDT.create_from_surface(mesh,0)
	for i in range(MDT.get_face_count()): #pa = point a, same for b and c
		var pa=MDT.get_vertex(MDT.get_face_vertex(i,0))
		var pb=MDT.get_vertex(MDT.get_face_vertex(i,1))
		var pc=MDT.get_vertex(MDT.get_face_vertex(i,2))
		var tri_area=calculate_triangle_area(pa,pb,pc)
		var tri_normal=Plane(pa,pb,pc).normal
		vol+=(pa.dot(tri_normal))*tri_area
	return abs(vol)/3


static func calculate_triangle_area(point1:Vector3,point2:Vector3,point3:Vector3):
	var a=point1.distance_to(point2)
	var b=point2.distance_to(point3)
	var c=point3.distance_to(point1)
	var s=(a+b+c)/2
	return sqrt(s*(s-a)*(s-b)*(s-c))

