extends Node3D

@export var anim_player_path: NodePath
@onready var anim: AnimationPlayer = get_node_or_null(anim_player_path)

const ANIM_BAT_SWING := "Bat|BatAction"
const ANIM_WALK      := "Heart|Walk"
const ANIM_IDLE      := "Heart|Idle"

func _ready() -> void:
	if anim == null:
		push_error("Set 'anim_player_path' to your AnimationPlayer in the Inspector.")
		return
	print("Animations:", anim.get_animation_list())
	# Optional: quick sanity test so you SEE it play on start:
	# anim.play(ANIM_BAT_SWING)

func _input(event: InputEvent) -> void:
	if anim == null:
		return
	if event.is_action_pressed("Bat"):
		_play_restart(ANIM_BAT_SWING)
	elif event.is_action_pressed("Walk"):
		_play_restart(ANIM_WALK)

func _play_restart(name: String) -> void:
	if not (name in anim.get_animation_list()):
		push_error("Missing animation: " + name)
		return
	if anim.current_animation == name and anim.is_playing():
		anim.seek(0.0, true)
	else:
		anim.play(name)
