extends Node3D

@export var y_rotation_speed:= 50
@export var model: Node3D 


func _process(delta: float) -> void:
	model.rotation_degrees += Vector3(0, y_rotation_speed, 0) * delta
