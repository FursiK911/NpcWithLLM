class_name OllamaStreamParser
extends RefCounted


static func parse(body: String) -> Dictionary:
	var assembled := ""
	for line in body.split("\n"):
		var normalized := line.strip_edges()
		if normalized.is_empty():
			continue
		var parsed := JSON.new()
		var parse_error := parsed.parse(normalized)
		if parse_error != OK:
			return {"error": LocalLlmError.create(LocalLlmError.INVALID_JSON, parsed.get_error_message())}
		if typeof(parsed.data) != TYPE_DICTIONARY:
			return {"error": LocalLlmError.create(LocalLlmError.INVALID_JSON, "Expected a stream object.")}
		var root: Dictionary = parsed.data
		if root.has("error"):
			return {"error": LocalLlmError.create(LocalLlmError.HTTP_ERROR, "Ollama stream error.")}
		if not root.has("done") or typeof(root.done) != TYPE_BOOL:
			return {"error": LocalLlmError.create(LocalLlmError.INVALID_JSON, "Missing stream completion flag.")}
		if root.has("message"):
			if typeof(root.message) != TYPE_DICTIONARY or typeof(root.message.get("content")) != TYPE_STRING:
				return {"error": LocalLlmError.create(LocalLlmError.INVALID_JSON, "Missing message.content.")}
			assembled += root.message.content
		if root.done:
			if root.get("done_reason", "") == "length":
				return {"error": LocalLlmError.create(LocalLlmError.INCOMPLETE_RESPONSE, "Generation token limit reached.")}
			if assembled.strip_edges().is_empty():
				return {"error": LocalLlmError.create(LocalLlmError.EMPTY_RESPONSE, "No visible content.")}
			return {"raw_response": assembled.strip_edges()}
	return {"error": LocalLlmError.create(LocalLlmError.INCOMPLETE_RESPONSE, "Stream ended without done=true.")}
