class_name CharacterDialog
extends Control

@export var current_dialog_id: String = "UNDEFINED"
@export var text_speed_per_character := .05

@export_file()
var file: String

@onready var text_label : RichTextLabel = %Text
@onready var next_display := %NextDisplay
@onready var close_display := %CloseDisplay

var _dialog: Dialog = Dialog.new()
var _revealing_text := false
var _dialog_entries := ["Undefined"]
var _current_entry := 0

signal dialog_opened()
signal dialog_closed()

func _ready() -> void:
	var dialog_file = FileAccess.get_file_as_string(file)
	_dialog.dict = JSON.parse_string(dialog_file)

func _input(event: InputEvent) -> void:
	if !visible:
		return
	
	if event.is_action_pressed("action") and !_revealing_text:
		if next_display.visible:
			next_display.visible = false
			_current_entry += 1
			_reveal_text()
		else:
			close_display.visible = false
			visible = false
			dialog_closed.emit()
			
	get_viewport().set_input_as_handled()

func show_dialog(dialog_id: String):
	visible = true
	dialog_opened.emit()
	
	_dialog_entries = _dialog.dialogs[dialog_id]
	_current_entry = 0
	
	_reveal_text()

func _reveal_text():
	_revealing_text = true
	%TalkNoise.play()
	
	text_label.visible_characters = 0
	text_label.text = _dialog_entries[_current_entry]
	
	var character_count = text_label.get_total_character_count()
	
	var reveal_tween = create_tween()
	
	reveal_tween.tween_property(text_label, "visible_characters", character_count, character_count * text_speed_per_character)
	
	await reveal_tween.finished
	
	%TalkNoise.stop()
	_revealing_text = false
	
	if (_current_entry +1) >= _dialog_entries.size():
		close_display.visible = true
	else:
		next_display.visible = true
