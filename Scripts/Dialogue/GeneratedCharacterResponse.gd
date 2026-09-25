class_name GeneratedCharacterResponse
extends RefCounted

const ALLOWED_EMOTIONS := ["angry", "happy", "sad", "thinking", "neutral"]

var message: String
var emotion: String


func _init(response_message: String, response_emotion: String) -> void:
	message = response_message
	emotion = response_emotion


static func parse(raw_response: String) -> Dictionary:
	var parser := JSON.new()
	var parse_error := parser.parse(raw_response)
	if parse_error != OK:
		return {"error": LocalLlmError.create(LocalLlmError.INVALID_JSON, "Character response was not valid JSON: %s" % parser.get_error_message())}
	if typeof(parser.data) != TYPE_DICTIONARY:
		return {"error": _empty_response_error()}

	var result: Dictionary = parser.data
	if not result.has("message") or typeof(result.message) != TYPE_STRING or result.message.strip_edges().is_empty():
		return {"error": _empty_response_error()}

	var emotion := "neutral"
	if result.has("emotion") and typeof(result.emotion) == TYPE_STRING:
		var candidate: String = result.emotion.strip_edges().to_lower()
		if candidate in ALLOWED_EMOTIONS:
			emotion = candidate
	return {"response": GeneratedCharacterResponse.new(result.message.strip_edges(), emotion)}


static func _empty_response_error() -> Dictionary:
	return LocalLlmError.create(LocalLlmError.EMPTY_RESPONSE, "Character response did not contain a non-empty string message.")
