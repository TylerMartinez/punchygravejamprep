extends Control
func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("action"):
		get_tree().change_scene_to_file("res://main_3d.tscn")
