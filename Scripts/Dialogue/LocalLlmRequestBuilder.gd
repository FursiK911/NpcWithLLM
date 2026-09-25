class_name LocalLlmRequestBuilder
extends RefCounted

const CHARACTER_RESPONSE_FORMAT := {
	"type": "object",
	"properties": {
		"message": {"type": "string"},
		"emotion": {"type": "string", "enum": ["angry", "happy", "sad", "thinking", "neutral"]},
	},
	"required": ["message", "emotion"],
	"additionalProperties": false,
}


static func create(
		model: String,
		context: Array[DialogueMessage],
		temperature: float,
		top_p: float,
		max_tokens: int,
		think: bool = false,
		stream: bool = true,
		context_tokens: int = 4096,
		presence_penalty: float = 0.0
	) -> Dictionary:
	if model.strip_edges().is_empty():
		return {"error": LocalLlmError.create(LocalLlmError.CONFIGURATION, "Model cannot be empty.")}
	if context.is_empty():
		return {"error": LocalLlmError.create(LocalLlmError.CONFIGURATION, "Request context is empty.")}

	var system_parts: Array[String] = []
	var chat_messages: Array[Dictionary] = []
	for message in context:
		if message.role.to_lower() == "system":
			var content := message.content.strip_edges()
			if not content.is_empty():
				system_parts.append(content)
		else:
			chat_messages.append(message.to_dictionary())
	if not system_parts.is_empty():
		chat_messages.push_front({"role": "system", "content": "\n\n".join(system_parts)})

	return {
		"payload": {
			"model": model.strip_edges(),
			"messages": chat_messages,
			"stream": stream,
			"options": {
				"temperature": temperature,
				"top_p": top_p,
				"num_predict": max_tokens,
				"num_ctx": context_tokens,
				"presence_penalty": presence_penalty,
				"repeat_penalty": 1.0,
			},
			"think": think,
			"format": CHARACTER_RESPONSE_FORMAT,
		},
	}
