extends AnimationPlayer

var swing = false

func _process(delta):
	if swing:
		if not is_playing():
			play("swing")  # Replace with your actual animation name
	else:
		if is_playing():
			stop()
