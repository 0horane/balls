extends Node

@onready var spawn_area = $"../TemporaryGround/MeshInstance3D"  # Enlaza el área de spawn en el inspector
var object_scene_path : String = "res://chair.tscn" # Ruta a la escena del objeto que deseas instanciar
var object_scene : PackedScene

func _ready():
	# Obtiene la referencia al área de spawn
	spawn_area = $"../TemporaryGround/MeshInstance3D"

	# Carga la escena del objeto
	object_scene = load(object_scene_path)

	if object_scene:
		print("El objeto se instanciará en el área de spawn al presionar la tecla 'P'.")

func spawn_random_object():    
	if spawn_area and object_scene:
		print(spawn_area)
		
		var random_position = Vector3(
			randf() * spawn_area.mesh.size.x * 2 - spawn_area.mesh.size.x,
			randf() * spawn_area.mesh.size.y * 2 - spawn_area.mesh.size.y,
			randf() * spawn_area.mesh.size.z * 2 - spawn_area.mesh.size.z
		)
		var new_object = object_scene.instantiate()
		new_object.transform.origin = random_position
		add_child(new_object)
		print("Object spawned at: ", random_position)

func _input(event):
	if event.is_action_pressed("spawn_object"):
		spawn_random_object()
