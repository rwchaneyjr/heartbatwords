extends Node3D
# ==============================================================================
# Word Pitch + Timed Hit + Return  (rotation-proof, per-instance desync)
# ==============================================================================
# Behavior
# 1) After a (possibly offset) delay, the word moves along ITS OWN forward.
# 2) At a configured time (per instance), we simulate a "hit" and reverse.
# 3) The word returns to launch and (by default) stops cleanly.
# 4) Optional: still allow collision-based hits in addition to timed hits.
#
# Notes
# - Forward is derived from rotation only (robust to -180° inspector rotation).
# - Use hit_time_offset / hit_time_jitter to keep multiple words out of sync.
# ==============================================================================

# ── Movement & timing ──────────────────────────────────────────────────────────
@export var move_speed: float = 5.0                # units/sec
@export var forward_limit: float = 93.0            # safety cap if you want it
@export var start_offset: float = 14.0             # spawn offset along forward
@export var start_delay: float = 0.5               # base delay before moving

# Per-instance desync knobs (set different values per word or use jitter)
@export var start_delay_offset: float = 0.0        # extra per-instance start delay
@export var start_delay_jitter: float = 0.0        # adds [0..jitter] random secs

# Timed "hit" (reverse) control
@export var hit_time: float = 1.0                  # seconds after moving to reverse; <0 disables timed hit
@export var hit_time_offset: float = 0.0           # extra per-instance offset to avoid sync
@export var hit_time_jitter: float = 0.0           # adds [0..jitter] random secs

# Return behavior
@export var return_speed_scale: float = 1.0        # < 1.0 if you want the return slower
@export var stop_at_start_after_hit: bool = true   # stop when back at launch

# Optional collision-based hit (in addition to timed hit)
@export var use_collision_hit: bool = false
@export var area_collider_path: NodePath           # set if using collision hits

# Animations
@export var swing_animation_name: String = "swing" # batter animation to play on hit
@export var play_batter_on_hit: bool = true

# Forward helpers
@export var invert_forward: bool = false           # flip if your asset's "front" is backwards

# Debugging
@export var debug_prints: bool = false

const EPS := 0.0001

# ── Internal state ─────────────────────────────────────────────────────────────
var launch_pos: Vector3
var dir: float = 0.0                               # +1 = out, -1 = back, 0 = idle
var moving: bool = false
var elapsed_total: float = 0.0                     # total time since _ready
var elapsed_moving: float = 0.0                    # time since movement began

var start_delay_effective: float = 0.0
var hit_time_effective: float = -1.0               # computed (may be <0 => disabled)

var area_collider: Area3D = null
var hit_triggered: bool = false                    # ensure we flip once (timed)

# ==============================================================================
# Lifecycle
# ==============================================================================
func _ready() -> void:
	# Compute forward and place at launch
	var forward := _forward_dir()
	launch_pos = global_transform.origin + forward * start_offset
	global_transform.origin = launch_pos

	# Compute effective times (adds offset/jitter)
	_compute_effective_times()

	# Hook up collisions (optional)
	if use_collision_hit:
		_connect_area_collider()

	# Start letter animations if present
	_set_animations_to_loop()
	_start_all_animations()

	# Initialize motion state
	dir = 0.0
	moving = false
	elapsed_total = 0.0
	elapsed_moving = 0.0
	hit_triggered = false

	if debug_prints:
		print("[Pitch] ready: launch=", launch_pos, " fwd=", forward, 
			  " start_delay_eff=", start_delay_effective,
			  " hit_time_eff=", hit_time_effective)

func _process(delta: float) -> void:
	elapsed_total += delta

	# A) Wait until it's time to start moving
	if not moving:
		if elapsed_total >= start_delay_effective:
			moving = true
			dir = 1.0
			elapsed_moving = 0.0
			if debug_prints: print("[Pitch] start moving, dir=+1")
		else:
			return

	# B) Advance along our rotation-based forward
	var forward := _forward_dir()
	var speed := move_speed
	if dir < 0.0:
		speed *= return_speed_scale

	global_transform.origin += forward * speed * dir * delta
	elapsed_moving += delta

	# C) Timed "hit" (reverse) once the scheduled time arrives
	#    (Only if enabled and not already triggered.)
	if not hit_triggered and hit_time_effective >= 0.0 and elapsed_moving >= hit_time_effective:
		_do_hit_reverse("timed")

	# D) Safety: limit how far forward we can go (optional clamp / bounce)
	var traveled := (global_transform.origin - launch_pos).dot(forward)
	if dir > 0.0 and traveled >= forward_limit - EPS:
		# If your hit_time is too large, we might reach the edge first.
		# In that case, clamp to edge and reverse (soft bounce) so we still turn.
		global_transform.origin = launch_pos + forward * forward_limit
		if not hit_triggered:
			_do_hit_reverse("limit-bounce")  # reverse if we hit edge before the timed hit
		else:
			dir = -1.0  # already hit; ensure we're going back

	# E) Stop (or bounce) when we return to start
	if dir < 0.0 and traveled <= 0.0 + EPS:
		global_transform.origin = launch_pos
		if stop_at_start_after_hit:
			dir = 0.0
			moving = false
			if debug_prints: print("[Pitch] back at start, stop")
		else:
			dir = 1.0
			if debug_prints: print("[Pitch] back at start, bounce to +1")

# ==============================================================================
# Hit / reverse helpers
# ==============================================================================
func _do_hit_reverse(reason: String) -> void:
	# Play batter animation (optional)
	if play_batter_on_hit:
		_play_swing_animation_on_batter()

	# Flip direction to return
	dir = -1.0
	hit_triggered = true
	if debug_prints:
		print("[Pitch] HIT -> reverse (reason=", reason, 
			  ", t=", elapsed_moving, "s, dir=-1)")

# ==============================================================================
# Time setup (adds offsets/jitter so multiple words aren't synchronized)
# ==============================================================================
func _compute_effective_times() -> void:
	# Seed RNG based on node path so each instance is stable but different
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(get_path())

	start_delay_effective = start_delay + start_delay_offset
	if start_delay_jitter > 0.0:
		start_delay_effective += rng.randf_range(0.0, start_delay_jitter)

	# Timed hit can be disabled by setting hit_time < 0
	if hit_time >= 0.0:
		hit_time_effective = hit_time + hit_time_offset
		if hit_time_jitter > 0.0:
			hit_time_effective += rng.randf_range(0.0, hit_time_jitter)
	else:
		hit_time_effective = -1.0  # disabled

# ==============================================================================
# Direction / forward math (rotation-only; robust to -180°)
# ==============================================================================
func _forward_dir() -> Vector3:
	# Vector3.FORWARD == (0, 0, -1); rotate it by our world rotation (ignores scale)
	var rot_q := global_transform.basis.get_rotation_quaternion()
	var dir_vec := (rot_q * Vector3.FORWARD).normalized()
	if invert_forward:
		return -dir_vec
	return dir_vec

# ==============================================================================
# Animations (letters with AnimationPlayers named "TextAction")
# ==============================================================================
func _set_animations_to_loop() -> void:
	for child in get_children():
		var ap: AnimationPlayer = child.get_node_or_null("AnimationPlayer")
		if ap:
			var anim: Animation = ap.get_animation("TextAction")
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR

func _start_all_animations() -> void:
	for child in get_children():
		var ap: AnimationPlayer = child.get_node_or_null("AnimationPlayer")
		if ap:
			var anim: Animation = ap.get_animation("TextAction")
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			ap.play("TextAction")

# ==============================================================================
# Optional collision-based hit
# ==============================================================================
func _connect_area_collider() -> void:
	if area_collider_path and String(area_collider_path) != "":
		area_collider = get_node_or_null(area_collider_path) as Area3D

	if area_collider != null:
		if not area_collider.body_entered.is_connected(_on_area_collision):
			area_collider.body_entered.connect(_on_area_collision)
		if not area_collider.area_entered.is_connected(_on_area_collision_area):
			area_collider.area_entered.connect(_on_area_collision_area)
	elif debug_prints:
		push_warning("`use_collision_hit` enabled but no Area3D set in `area_collider_path`.")

func _on_area_collision(body: Node) -> void:
	if not use_collision_hit:
		return
	# Treat contact with this node (or its children) as a "hit"
	if body == self or is_ancestor_of(body):
		_do_hit_reverse("collision-body")

func _on_area_collision_area(area: Area3D) -> void:
	if not use_collision_hit:
		return
	# If the area belongs to us, it's a "hit"
	if area.get_parent() == self:
		_do_hit_reverse("collision-area")

# ==============================================================================
# Batter swing (optional)
# ==============================================================================
func _play_swing_animation_on_batter() -> void:
	# Try a sibling named "Batter" first.
	var batter := get_node_or_null("../Batter")
	if batter:
		var ap: AnimationPlayer = batter.get_node_or_null("AnimationPlayer")
		if ap:
			ap.play(swing_animation_name)
			return
	# Fallback: scan scene root for any node with "batter" in the name
	for child in get_tree().current_scene.get_children():
		if child.name.to_lower().contains("batter"):
			var ap2: AnimationPlayer = child.get_node_or_null("AnimationPlayer")
			if ap2:
				ap2.play(swing_animation_name)
				return
