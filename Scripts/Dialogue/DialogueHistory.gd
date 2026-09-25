class_name DialogueHistory
extends RefCounted

const DialogueMessageResource = preload("res://Scripts/Dialogue/DialogueMessage.gd")

var _max_messages: int
var _max_characters: int
var _pairs: Array[Dictionary] = []

var message_count: int:
	get:
		return _pairs.size() * 2

var character_count: int:
	get:
		var total := 0
		for pair in _pairs:
			total += pair.player.content.length() + pair.character.content.length()
		return total

var messages: Array[DialogueMessageResource]:
	get:
		var result: Array[DialogueMessageResource] = []
		for pair in _pairs:
			result.append(pair.player)
			result.append(pair.character)
		return result


func _init(max_messages: int = 32, max_characters: int = 8000) -> void:
	_max_messages = max_messages
	_max_characters = max_characters


func add_pair(player_message: String, character_response: String) -> void:
	if player_message.strip_edges().is_empty() or character_response.strip_edges().is_empty():
		return

	_pairs.append({
		"player": DialogueMessageResource.new("user", player_message.strip_edges()),
		"character": DialogueMessageResource.new("assistant", character_response.strip_edges()),
	})
	_trim_to_limits()


func _trim_to_limits() -> void:
	while _pairs.size() * 2 > _max_messages or character_count > _max_characters:
		if _pairs.is_empty():
			return
		_pairs.pop_front()
