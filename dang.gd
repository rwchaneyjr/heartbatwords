extends Node3D

@export var target: RigidBody3D       # drag your bat (RigidBody3D)
@export var start_position: Node3D    # drag your start position Node3D
@export var speed: float = 5.0
@export var arrive_distance: float = 0.2   # how close counts as "arrived"

var going_to_bat := true              # true → toward bat, false → return home

func _ready() -> void:
	var area := $Area3D
	if area:
		area.body_entered.connect(_on_hit)
		area.area_entered.connect(_on_hit)

	_play_text_action_on_self_and_children()


func _physics_process(delta: float) -> void:
	if target == null or start_position == null:
		return

	if going_to_bat:
		# --- Move toward the bat (RigidBody) ---
		var to := target.global_position
		to.y = global_position.y  # keep level flight
		global_position = global_position.move_toward(to, speed * delta)

		# --- Flip if very close (arrived) ---
		if global_position.distance_to(to) <= arrive_distance:
			print("Reached bat, turning back!")
			_flip(to)
	else:
		# --- Move back toward start position ---
		var home := start_position.global_position
		home.y = global_position.y
		global_position = global_position.move_toward(home, speed * delta)

		# --- Flip if back at start (optional) ---
		if global_position.distance_to(home) <= arrive_distance:
			print("Back home, going to bat again!")
			_flip(home)


func _on_hit(_body: Node) -> void:
	# Triggered when collider hits bat
	if target != null:
		print("💥 Collision with bat! Reversing direction.")
		_flip(target.global_position)


func _flip(point: Vector3) -> void:
	going_to_bat = not going_to_bat
	var push := (global_position - Vector3(point.x, global_position.y, point.z)).normalized()
	if push.length() > 0.0:
		global_position += push * arrive_distance   # tiny nudge off surface


# --- Optional animation helper ---
func _play_text_action_on_self_and_children() -> void:
	var ap := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap and ap.has_animation("TextAction"):
		ap.play("TextAction")
		ap.animation_finished.connect(func(anim_name):
			if anim_name == "TextAction": ap.play("TextAction"))
	for child in get_children():
		var cap := child.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if cap and cap.has_animation("TextAction"):
			cap.play("TextAction")
			cap.animation_finished.connect(func(anim_name):
				if anim_name == "TextAction": cap.play("TextAction"))
