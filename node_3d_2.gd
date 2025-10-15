extends Node3D

@export var target: Node3D
@export var start_position: Node3D
@export var speed: float = 10.0

var going_to_bat := true
var direction := Vector3.ZERO

func _ready():
	if target:
		# compute flat direction (ignore Y)
		var diff = target.global_position - global_position
		diff.y = 0.0
		direction = diff.normalized()

	var area := $Area3D
	if area:
		area.body_entered.connect(_on_hit)
# --- Drop-in: always play "TextAction" on self + child letters ---


	_play_text_action_on_self_and_children()


func _play_text_action_on_self_and_children() -> void:
	# on this node
	var ap := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap and ap.has_animation("TextAction"):
		ap.play("TextAction")
		ap.animation_finished.connect(
			func(anim_name):
				if anim_name == "TextAction": ap.play("TextAction")
		)

	# on direct children (letters)
	for child in get_children():
		var cap := child.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if cap and cap.has_animation("TextAction"):
			cap.play("TextAction")
			cap.animation_finished.connect(
				func(anim_name):
					if anim_name == "TextAction": cap.play("TextAction")
			)

func _physics_process(delta):
	if target == null or start_position == null:
		return

	if going_to_bat:
		# move flat toward bat
		global_position += direction * speed * delta
	else:
		# compute new flat direction back to start each frame
		var back_dir = start_position.global_position - global_position
		back_dir.y = 0.0
		global_position += back_dir.normalized() * speed * delta

func _on_hit(_body):
	print("Hit the bat! Returning to start.")
	going_to_bat = false
