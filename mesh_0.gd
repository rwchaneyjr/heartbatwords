extends MeshInstance3D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.name == "WordMesh":
		var bat = get_node("../Heart/Bat/AnimationPlayer")
		bat.play("Swing")
		body.reverse_direction()  # Assumes WordMesh has this function
