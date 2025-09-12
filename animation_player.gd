extends AnimationPlayer
## Attach this script to your AnimationPlayer node.

# Exact animation names in your AnimationPlayer
const ANIM_BAT_SWING := "Bat|BatAction"
const ANIM_WALK      := "Heart|Walk"

func _ready() -> void:
	print("Animations available:", get_animation_list())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match OS.get_keycode_string(event.keycode):
			"F": _play_restart(ANIM_BAT_SWING)  # press F key to swing Bat
			"G": _play_restart(ANIM_WALK)       # press G key to play Walk

func _play_restart(name: String) -> void:
	if not has_animation(name):
		push_error("Missing animation: " + name)
		return
	if current_animation == name and is_playing():
		seek(0.0, true)  # restart from beginning
	else:
		play(name)
