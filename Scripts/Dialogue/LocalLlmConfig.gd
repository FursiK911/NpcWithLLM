class_name LocalLlmConfig
extends Resource

@export var base_url: String = "http://127.0.0.1:11434"
@export var endpoint_path: String = "/api/chat"
@export var model_name: String = "qwen35-9b-q4km-bartowski:latest"
@export_range(1.0, 300.0, 1.0) var timeout_seconds: float = 60.0
@export_range(0.0, 2.0, 0.05) var temperature: float = 0.7
@export_range(0.0, 1.0, 0.05) var top_p: float = 0.8
@export_range(1, 4096, 1) var max_tokens: int = 256
@export_range(2048, 16384, 1024) var context_tokens: int = 8192
@export_range(-2.0, 2.0, 0.1) var presence_penalty: float = 0.0
@export_range(2, 200, 2) var max_history_messages: int = 32
@export_range(200, 60000, 100) var max_history_characters: int = 8000


func validate_configuration() -> Dictionary:
	var trimmed_base := base_url.strip_edges().trim_suffix("/")
	if not _is_loopback_url(trimmed_base):
		return LocalLlmError.create(LocalLlmError.CONFIGURATION, "BaseUrl must be a loopback HTTP(S) URL.")
	if endpoint_path.strip_edges().is_empty():
		return LocalLlmError.create(LocalLlmError.CONFIGURATION, "EndpointPath cannot be empty.")
	if endpoint_path.contains("://") or endpoint_path.contains("?") or endpoint_path.contains("#"):
		return LocalLlmError.create(LocalLlmError.CONFIGURATION, "EndpointPath must be a relative API path.")
	if model_name.strip_edges().is_empty():
		return LocalLlmError.create(LocalLlmError.CONFIGURATION, "ModelName cannot be empty.")
	if timeout_seconds <= 0.0:
		return LocalLlmError.create(LocalLlmError.CONFIGURATION, "TimeoutSeconds must be positive.")
	if temperature < 0.0 or temperature > 2.0:
		return LocalLlmError.create(LocalLlmError.CONFIGURATION, "Temperature must be between 0 and 2.")
	if top_p <= 0.0 or top_p > 1.0:
		return LocalLlmError.create(LocalLlmError.CONFIGURATION, "TopP must be in (0, 1].")
	if max_tokens <= 0:
		return LocalLlmError.create(LocalLlmError.CONFIGURATION, "MaxTokens must be positive.")
	if context_tokens < 2048 or context_tokens > 16384 or max_tokens >= context_tokens:
		return LocalLlmError.create(LocalLlmError.CONFIGURATION, "Invalid context or response budget.")
	if not is_finite(presence_penalty) or presence_penalty < -2.0 or presence_penalty > 2.0:
		return LocalLlmError.create(LocalLlmError.CONFIGURATION, "PresencePenalty must be between -2 and 2.")
	if max_history_messages < 2 or max_history_messages % 2 != 0:
		return LocalLlmError.create(LocalLlmError.CONFIGURATION, "MaxHistoryMessages must be even and at least two.")
	if max_history_characters < 200:
		return LocalLlmError.create(LocalLlmError.CONFIGURATION, "MaxHistoryCharacters must be at least 200.")
	return {}


func get_endpoint_url() -> String:
	var validation := validate_configuration()
	if not validation.is_empty():
		return ""
	return base_url.strip_edges().trim_suffix("/") + "/" + endpoint_path.strip_edges().trim_prefix("/")


func get_model_list_url() -> String:
	return base_url.strip_edges().trim_suffix("/") + "/api/tags"


func _is_loopback_url(url: String) -> bool:
	var expression := RegEx.new()
	expression.compile("^https?://(\\[[0-9A-Fa-f:]+\\]|[^/:?#]+)(?::[0-9]{1,5})?(?:/.*)?$")
	var found := expression.search(url)
	if not found:
		return false
	var host := found.get_string(1).to_lower()
	if host in ["localhost", "127.0.0.1", "[::1]"]:
		return true
	if host.begins_with("127."):
		var octets := host.split(".")
		if octets.size() == 4:
			for octet in octets:
				if not octet.is_valid_int() or int(octet) < 0 or int(octet) > 255:
					return false
			return true
	return false
