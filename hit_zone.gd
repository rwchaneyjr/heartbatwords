
# BatHitZone_GroupToggle.gd  (attach to Bat/HitZone Node3D)
extends Node3D

@export var enabled: bool = true
@export var size: Vector3 = Vector3(4, 3, 6)    # width, height, depth of the hit box
@export var group_name: String = "word"         # all words go in this group
@export var cooldown_sec: float = 0.25          # per-word cooldown
@export var auto_refresh_group_every: float = 1.5  # seconds; set 0 to disable
@export var debug_print: bool = false

var _monitored: Array[Node3D] = []
var _last_hit: Dictionary = {}   # Node -> last hit time (float seconds)
var _refresh_t := 0.0

func _ready():
	_refresh_group()

func set_enabled(v: bool) -> void:
	enabled = v

func _refresh_group() -> void:
	_monitored.clear()
	for n in get_tree().get_nodes_in_group(group_name):
		if n is Node3D:
			_monitored.append(n)
	if debug_print:
		print("HitZone watching ", _monitored.size(), " word(s).")

func _physics_process(delta: float) -> void:
	if !enabled:
		return

	if auto_refresh_group_every > 0.0:
		_refresh_t -= delta
		if _refresh_t <= 0.0:
			_refresh_t = auto_refresh_group_every
			_refresh_group()

	var now: float = Time.get_ticks_msec() / 1000.0
	for w in _monitored:
		if !is_instance_valid(w):
			continue
		# convert the word's world position into this zone's local space
		var local := to_local(w.global_position)
		if absf(local.x) <= size.x * 0.5 \
		and absf(local.y) <= size.y * 0.5 \
		and absf(local.z) <= size.z * 0.5:
			var last: float = float(_last_hit.get(w, -INF))
			if now - last >= cooldown_sec:
				_last_hit[w] = now
				if w.has_method("bounce_from"):
					if debug_print: print("Hit ", w.name)
					w.call("bounce_from", global_position)  # tell that word to retreat
