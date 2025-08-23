extends Area3D
@export var animation_controller: AnimationPlayer

func _on_area_entered(area):
	# Ignore the bat and heart
	if area.name == "bat" or area.name == "heart":
		return

	# If "darn" or "dang" collides, trigger the animation
	if area.name == "darn" or area.name == "dang":
		if animation_controller:
			if animation_controller.is_playing():
				animation_controller.stop()
			else:
				animation_controller.play("swing")  # Play the animation directly
