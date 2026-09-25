class_name DialogueMessage
extends RefCounted

var role: String
var content: String


func _init(message_role: String = "", message_content: String = "") -> void:
	role = message_role
	content = message_content


func to_dictionary() -> Dictionary:
	return {"role": role, "content": content}
