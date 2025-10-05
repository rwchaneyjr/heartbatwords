# WordChaser_Min.gd  (attach to the word's root Node3D)
extends Node3D

@export var target: Node3D
@export var speed: float = 9.0
@export var flatten_y: bool = true  # keep motion on ground plane

var moving_toward: bool = true  # true = go to target, false = go away

func _physics_process(delta: float) -> void:
	if target == null:
		return

	var d := target.global_position - global_position
	if flatten_y:
		d.y = 0.0
	if d.length_squared() == 0.0:
		return

	var dir := d.normalized()
	var step := speed * delta

	if moving_toward:
		global_position += dir * step
	else:
		global_position -= dir * step

# Called by the bat's hit zone when the word is inside the box
func bounce_from(_bat_pos: Vector3) -> void:
	moving_toward = not moving_toward  # instantly flip direction
