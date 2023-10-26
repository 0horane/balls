extends Node

# Puedes agregar configuraciones específicas del área si es necesario.
# Por ejemplo, definir una forma específica, cambiar las colisiones, etc.

func _on_Area_body_entered(body):
	if body.has_method("spawn_random_object"):
		body.spawn_random_object()
