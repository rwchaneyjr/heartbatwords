extends MeshInstance3D

@export var animation_player_path: NodePath
var anim_player: AnimationPlayer

func _ready():
	# Get reference to the AnimationPlayer node
	anim_player = get_node(animation_player_path)

func _process(delta):
	# Example: press "B" to play bat animation
	if Input.is_action_just_pressed("Bat"):
		if anim_player.has_animation("Bat"):
			anim_player.play("Bat")

	# Example: press "W" to play walk animation
	if Input.is_action_just_pressed("walk_action"):
		if anim_player.has_animation("Walk"):
			anim_player.play("Walk")
