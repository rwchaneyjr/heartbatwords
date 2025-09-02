
extends Node3D

# Settings you can adjust
@export var pitch_speed: float = 5.1  # How fast the word moves
@export var max_z_distance: float = 20 # How far forward before it bounces back
@export var start_z_position: float = -80 # Starting position behind batter (positive because of rotation)
@export var swing_animation_name: String = "swing"  # Name of the swing animation
@export var area_collider_path: NodePath  # Path to your Area3D collider
@export var start_delay: float = 7
# Internal variables
var moving_forward: bool = true
var original_position: Vector3
var area_collider: Area3D  # Reference to your separate Area3D collider

func _ready():
	# Remember where we started
	original_position = global_position
	
	# Set starting position
	global_position.z = start_z_position
	await get_tree().create_timer(start_delay).timeout
	# Connect to your separate Area3D collider
	setup_area_collider_connection()
	
	# Set all animations to loop first
	set_animations_to_loop()
	
	# Start all the animations on our children
	start_all_animations()

func _process(delta):
	# Debug: Print the current position
	print("Current Z position: ", global_position.z)
	print("Moving forward: ", moving_forward)
	
	# Move the word based on direction
	if moving_forward:
		# Move toward the batter
		global_position.z += pitch_speed * delta
		print("Moving forward, new Z: ", global_position.z)
	
		# Check if we've reached the max distance - time to go back!
		if global_position.z >= max_z_distance:
			moving_forward = false
			print("Reached max distance, turning around!")
	else: 
		# Move away from the batter
		global_position.z -= pitch_speed * delta
		print("Moving backward, new Z: ", global_position.z)
		
		# Reset when it goes back far enough
		if global_position.z <= start_z_position:
			print("Reset!")
			reset_pitch()

func set_animations_to_loop():
	# Make sure all animations are set to loop
	for child in get_children():
		var anim_player = child.get_node_or_null("AnimationPlayer")
		if anim_player:
			var animation = anim_player.get_animation("TextAction")
			if animation:
				animation.loop_mode = Animation.LOOP_LINEAR
				print("Set loop for: ", child.name)

func start_all_animations():
	# Play the "TextAction" animation on all 4 children
	for child in get_children():
		# Look for AnimationPlayer as a child of each letter
		var anim_player = child.get_node_or_null("AnimationPlayer")
		if anim_player and anim_player.has_method("play"):
			print("Playing animation on: ", child.name)
			# Force the animation to loop every time
			var animation = anim_player.get_animation("TextAction")
			if animation:
				animation.loop_mode = Animation.LOOP_LINEAR
			anim_player.play("TextAction")
		else:
			print("No AnimationPlayer found on: ", child.name)

func reset_pitch():
	# Reset everything to start over
	moving_forward = true
	global_position = original_position
	global_position.z = start_z_position
	start_all_animations()

# Optional: Call this function to manually start a new pitch
func pitch_word():
	reset_pitch()

func setup_area_collider_connection():
	# Connect to your separate Area3D collider
	if area_collider_path:
		area_collider = get_node(area_collider_path)
	else:
		# Try to find it automatically by name
		area_collider = get_node_or_null("../Area3D")  # Adjust path as needed
		if not area_collider:
			area_collider = get_node_or_null("../BatterArea")  # Try another common name
		if not area_collider:
			# Search the scene for Area3D nodes
			var scene_root = get_tree().current_scene
			for child in scene_root.get_children():
				if child is Area3D and child != self:
					area_collider = child
					break
	
	if area_collider:
		# Connect the collision signals
		if not area_collider.body_entered.is_connected(_on_area_collision):
			area_collider.body_entered.connect(_on_area_collision)
		if not area_collider.area_entered.is_connected(_on_area_collision_area):
			area_collider.area_entered.connect(_on_area_collision_area)
		print("Connected to Area3D collider: ", area_collider.name)
	else:
		print("Could not find Area3D collider - please set the path in Inspector")

func _on_area_collision(body):
	# When something enters your Area3D collider
	print("Area3D detected collision with body: ", body.name)
	# Check if it's our word that entered
	if body == self or is_ancestor_of(body):
		play_swing_animation_on_batter()

func _on_area_collision_area(area):
	# When an area enters your Area3D collider  
	print("Area3D detected collision with area: ", area.name)
	# Check if it's related to our word
	if area.get_parent() == self:
		play_swing_animation_on_batter()

func play_swing_animation_on_batter():
	# Play the swing animation - you'll need to modify this based on your batter setup
	print("Playing swing animation!")
	
	# Method 1: If your batter is in the scene tree, find it by name
	var batter = get_node_or_null("../Batter")  # Adjust path as needed
	if batter:
		var batter_anim = batter.get_node_or_null("AnimationPlayer")
		if batter_anim:
			batter_anim.play(swing_animation_name)
			return
	
	# Method 2: Search for any node with "batter" in the name
	var scene_root = get_tree().current_scene
	for child in scene_root.get_children():
		if child.name.to_lower().contains("batter"):
			var anim_player = child.get_node_or_null("AnimationPlayer")
			if anim_player:
				anim_player.play(swing_animation_name)
				return
