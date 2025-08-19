extends Area3D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.name == "Bat":
		var anim_player = body.get_node("AnimationPlayer")
		anim_player.play("Swing")

		var word = get_parent() as RigidBody3D
		word.reverse_direction()
