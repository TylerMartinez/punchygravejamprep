extends CharacterBody2D

#NOTE: This code is crusty the animation code is just set to the idle animations as there are no true walk cycles built
#Feel free to destroy this shit, also the puzzle may not even work wihtout forcing the player to the grid
#Unsure ¯\_(ツ)_/¯
#Ripped from my other project so there is also enter exit code that is not functional rn

#ALSO weird bug but going left and right on the bottom walls causes the character to move in line with grid - only the lower walls easy to reproduce
#My guess magnets in the lower walls.

const MOTION_SPEED = 100 # Pixels/second.

var last_direction = Vector2(1, 0)

var anim_directions = {
	"idle": [
		["side_right_walk", false],
		["front_right_walk", false],
		["front_walk", false],
		["front_left_walk", false],
		["side_left_walk", false],
		["back_left_walk", false],
		["back_walk", false],
		["back_right_walk", false],
	],
	"walk": [
		["side_right_walk", false],
		["front_right_walk", false],
		["front_walk", false],
		["front_left_walk", false],
		["side_left_walk", false],
		["back_left_walk", false],
		["back_walk", false],
		["back_right_walk", false],
	],
}


func _physics_process(_delta):
	var input_dir = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		(Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")) / 2
	)

	# If any input is pressed, update last_direction even if movement fails
	if input_dir.length() > 0:
		last_direction = input_dir.normalized()

	# Movement velocity (this will be zero if blocked by walls, but that's fine)
	velocity = input_dir.normalized() * MOTION_SPEED
	move_and_slide()

	# Animation depends on input, not actual velocity
	if input_dir.length() > 0:
		update_animation("walk")
	else:
		update_animation("idle")


func update_animation(anim_set):
	var angle = rad_to_deg(last_direction.angle()) + 22.5
	var slice_dir = int(floor(angle / 45.0)) % 8

	$AnimatedSprite2D.play(anim_directions[anim_set][slice_dir][0])
	$AnimatedSprite2D.flip_h = anim_directions[anim_set][slice_dir][1]


func _on_area_2d_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
