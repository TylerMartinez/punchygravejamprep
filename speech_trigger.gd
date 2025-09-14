class_name SpeechTrigger
extends Area3D

@export var speech_indicator : Sprite3D
@export var speech_available_indicator: Sprite3D
@export var dialog_id: String
@export var dialog : CharacterDialog

var _exhausted_dialog := false

func _input(event: InputEvent) -> void:
	if speech_indicator.visible:
		
		if event.is_action_pressed("action"):
			speech_indicator.visible = false
			dialog.show_dialog(dialog_id)
			_exhausted_dialog = true

func _on_body_entered(body: Node3D) -> void:
	speech_indicator.visible = true
	speech_available_indicator.visible = false

func _on_body_exited(body: Node3D) -> void:
	speech_indicator.visible = false
	
	if !_exhausted_dialog:
		speech_available_indicator.visible = true
