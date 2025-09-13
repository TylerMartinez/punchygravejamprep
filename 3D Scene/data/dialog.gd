class_name Dialog
extends Resource

var dict: Dictionary :
	set(value):
		scene = value["scene"]
		author = value["author"]
		dialogs = value["dialogs"]

var scene: String
var author: String

var dialogs: Dictionary
