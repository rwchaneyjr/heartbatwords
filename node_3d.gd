extends Node3D

@export var start_delay: float = 2.0
@export var pitch_speed: float = 27.0
@export var hit_speed: float = 15.0
@export var friction: float = 0.0
@export var lock_y: bool = true
@export var rotate_y_180: bool = true

# Reverse when crossing this Z
@export var hit_trigger_z: float = 97.0

# Letters live here (optional). If empty, we'll use this node's direct children.
@export var letters_container: NodePath = NodePath("")

# --- Wave / snake animation settings (per-letter) ---
@export var wave_cycle: float = 1.2      # seconds for a full wave
@export var wave_amp_y: float = 0.0      # vertical bob amplitude
@export var wave_amp_x: float = 0.12     # sideways sway amplitude
@export var scale_amp: float = 0.20      # +/- scale pulse
@export var phase_gap: float = 0.50      # seconds between letters
@export var roll_amp_deg: float = 8.0    # tilt each letter

# caches for wave animation
var _letters: Array[Node3D] = []
var _base_pos: Array[Vector3] = []
var _base_scale: Array[Vector3] = []
var _base_rot_z: Array[float] = []
var _wave_t: float = 0.0

# Movement settings
@export var speed: float = 9.0
@export var reverse_z: float = 98
var velocity: float = 1.0      # 1 = forward, -1 = backward
var prev_z: float = 0.0
var _start_y: float = 0.0


func _ready() -> void:
	if rotate_y_180:
		rotate_y(PI)

	_start_y = global_position.y
	prev_z = global_position.z

	_gather_letters()

	await get_tree().create_timer(start_delay).timeout


func _physics_process(delta: float) -> void:
	# Move along Z using velocity sign
	global_position.z += velocity * speed * delta

	# Reverse when crossing hit_trigger_z
	var z := global_position.z
	if global_position.z >= hit_trigger_z:
		velocity = -velocity
		_pop_letters()  # tiny squash/pop on reversal
	prev_z = z

	# Keep Y locked if desired
	if lock_y:
		global_position.y = _start_y


func _process(delta: float) -> void:
	# Apply per-letter wave each frame
	_apply_wave(delta)


# --- Helpers ------------------------------------------------------------

func _gather_letters() -> void:
	_letters.clear()
	_base_pos.clear()
	_base_scale.clear()
	_base_rot_z.clear()

	var holder: Node = self
	if letters_container != NodePath(""):
		var n := get_node_or_null(letters_container)
		if n:
			holder = n

	for c in holder.get_children():
		if c is Node3D:
			var n3 := c as Node3D
			_letters.append(n3)
			_base_pos.append(n3.position)      # local pos
			_base_scale.append(n3.scale)       # local scale
			_base_rot_z.append(n3.rotation.z)  # local Z rotation


# Tiny squash on impact
func _pop_letters() -> void:
	for i in _letters.size():
		var k := _letters[i]
		k.scale = _base_scale[i] * 1.1


# Animate letters with a traveling wave feel
func _apply_wave(delta: float) -> void:
	if _letters.is_empty():
		return

	_wave_t = fmod(_wave_t + delta, wave_cycle)
	var two_pi := TAU

	for i in _letters.size():
		var L := _letters[i]
		var base_p := _base_pos[i]
		var base_s := _base_scale[i]
		var base_rz := _base_rot_z[i]

		# phase offset per letter so the wave travels across them
		var phase := ((_wave_t - float(i) * phase_gap) / wave_cycle) * two_pi

		# position offsets
		var dy := sin(phase) * wave_amp_y
		var dx := cos(phase) * wave_amp_x
		L.position = base_p + Vector3(dx, dy, 0.0)

		# scale pulse
		var s := 1.0 + sin(phase) * scale_amp
		L.scale = base_s * s

		# tilt for a rollercoaster feel
		var tilt := deg_to_rad(sin(phase) * roll_amp_deg)
		L.rotation.z = base_rz + tilt
