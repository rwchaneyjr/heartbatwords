extends Node3D

@export var target: Node3D
@export var speed: float = 20
@export var disappear_distance: float = 2.0

func _ready():
	var area = get_node_or_null("Area3D")
	if area:
		area.area_entered.connect(_on_collision)
		area.body_entered.connect(_on_collision)
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

func _process(delta):
	if target:
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * speed * delta
		
		# Check distance and disappear if close enough
		var distance_to_target = global_position.distance_to(target.global_position)
		if distance_to_target < disappear_distance:
			queue_free()

func _on_collision(body):
	if body.is_in_group("heart"):
		queue_free()

func set_target(target_node: Node3D):
	target = target_node
