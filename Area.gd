extends Node

func _on_Area_body_entered(body):
	if body.has_method("spawn_random_object"):
		body.spawn_random_object()
