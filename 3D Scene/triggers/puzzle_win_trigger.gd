extends Area3D

@export var control_to_display: Control

func _on_body_entered(body: Node3D) -> void:
	control_to_display.visible = true
