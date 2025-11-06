extends AudioStreamPlayer


func _on_puzzle_win_trigger_body_entered(_body: Node3D) -> void:
	stop()
	
	stream = load("res://assets/sounds/song_2.ogg")
	
	play()
