extends Node3D

@export var speed: float = 5.0   # Movement speed

func _process(delta: float) -> void:
	var input_vector = Vector3.ZERO

	# WASD / Arrow key movement
	if Input.is_action_pressed("ui_up"):    # W / Up Arrow
		input_vector.z -= 1
	if Input.is_action_pressed("ui_down"):  # S / Down Arrow
		input_vector.z += 1
	if Input.is_action_pressed("ui_left"):  # A / Left Arrow
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right"): # D / Right Arrow
		input_vector.x += 1

	# Normalize so diagonal isn’t faster
	if input_vector != Vector3.ZERO:
		input_vector = input_vector.normalized()

	# Apply movement
	translate(input_vector * speed * delta)
