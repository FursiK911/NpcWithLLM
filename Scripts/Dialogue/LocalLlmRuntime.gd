class_name LocalLlmRuntime
extends Node

const DialogueMessageResource = preload("res://Scripts/Dialogue/DialogueMessage.gd")
const OllamaServerControllerResource = preload("res://Scripts/Dialogue/OllamaServerController.gd")

var _config: LocalLlmConfig
var _http_request: HTTPRequest
var _server: OllamaServerControllerResource
var _disposed := false


func _ready() -> void:
	_http_request = HTTPRequest.new()
	_http_request.use_threads = true
	_http_request.body_size_limit = 1024 * 1024
	add_child(_http_request)


func _exit_tree() -> void:
	shutdown()


func configure(config: LocalLlmConfig) -> void:
	_config = config
	if _server != null:
		_server.shutdown()
	var executable := _resolve_ollama_executable()
	var executable_path: String = executable.path
	var models_directory: String = executable_path.get_base_dir().path_join("models")
	_server = OllamaServerControllerResource.new(
		_config.base_url,
		executable.path,
		executable.expected_sha256,
		30.0,
		models_directory
	)
	if _http_request != null:
		_http_request.timeout = _config.timeout_seconds


func prepare_async() -> Dictionary:
	if _config == null:
		return {"error": LocalLlmError.create(LocalLlmError.CONFIGURATION, "LocalLlmConfig is missing.")}
	var validation := _config.validate_configuration()
	if not validation.is_empty():
		return {"error": validation}
	var available: Dictionary = await _server.ensure_server_available(_probe_endpoint)
	if available.has("error"):
		_server.stop_owned_process()
		_log_error("preparation", available.error)
		return available

	var model_result := await _ensure_configured_model_available()
	if model_result.has("error"):
		_server.stop_owned_process()
		return model_result

	# Пробная генерация загружает веса и инициализирует тот же бюджет контекста, что использует диалог.
	var warmup := await generate_async([DialogueMessageResource.new("user", "Ответь одним словом: готов.")])
	if warmup.has("error"):
		_server.stop_owned_process()
		return warmup
	return {}


func generate_async(context: Array[DialogueMessageResource]) -> Dictionary:
	if _disposed:
		return {"error": LocalLlmError.create(LocalLlmError.NETWORK_ERROR, "LocalLlmRuntime is shut down.")}
	var validation := _config.validate_configuration()
	if not validation.is_empty():
		return {"error": validation}
	var available: Dictionary = await _server.ensure_server_available(_probe_endpoint)
	if available.has("error"):
		_log_error("generation", available.error)
		return available

	var payload_result := LocalLlmRequestBuilder.create(
		_config.model_name,
		context,
		_config.temperature,
		_config.top_p,
		_config.max_tokens,
		false,
		true,
		_config.context_tokens,
		_config.presence_penalty
	)
	if payload_result.has("error"):
		return payload_result

	var started_at := Time.get_ticks_msec()
	var request_result: Dictionary = await _perform_request(
		_config.get_endpoint_url(),
		HTTPClient.METHOD_POST,
		JSON.stringify(payload_result.payload),
		_config.timeout_seconds
	)
	if request_result.has("error"):
		if request_result.error.kind == LocalLlmError.NETWORK_ERROR:
			_server.mark_server_unavailable()
		_log_error("generation", request_result.error)
		return request_result
	if request_result.status < 200 or request_result.status >= 300:
		var http_error := LocalLlmError.create(LocalLlmError.HTTP_ERROR, "HTTP %d" % request_result.status)
		_log_error("generation", http_error)
		return {"error": http_error}

	var stream_result := _parse_stream_response(request_result.body)
	if stream_result.has("error"):
		_log_error("generation", stream_result.error)
		return stream_result
	print("LocalLlmRuntime completed in %d ms." % (Time.get_ticks_msec() - started_at))
	return {"raw_response": stream_result.raw_response}


func shutdown() -> void:
	if _disposed:
		return
	_disposed = true
	if _http_request != null and _http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_request.cancel_request()
	if _server != null:
		_server.shutdown()


func _ensure_configured_model_available() -> Dictionary:
	var response: Dictionary = await _perform_request(
		_config.get_model_list_url(),
		HTTPClient.METHOD_GET,
		"",
		_config.timeout_seconds
	)
	if response.has("error"):
		if response.error.kind == LocalLlmError.NETWORK_ERROR:
			_server.mark_server_unavailable()
		_log_error("model check", response.error)
		return response
	if response.status < 200 or response.status >= 300:
		return {"error": LocalLlmError.create(LocalLlmError.HTTP_ERROR, "Ollama model list returned HTTP %d." % response.status)}

	var parsed := _parse_json(response.body)
	if parsed.has("error"):
		return parsed
	if typeof(parsed.data) != TYPE_DICTIONARY or typeof(parsed.data.get("models")) != TYPE_ARRAY:
		return {"error": LocalLlmError.create(LocalLlmError.INVALID_JSON, "Ollama model list is missing the models array.")}
	for model in parsed.data.models:
		if typeof(model) == TYPE_DICTIONARY and model.get("name", "") == _config.model_name:
			return {}
	return {"error": LocalLlmError.model_unavailable(_config.model_name)}


func _probe_endpoint(url: String, timeout_seconds: float) -> Dictionary:
	return await _perform_request(url, HTTPClient.METHOD_GET, "", timeout_seconds)


func _perform_request(url: String, method: int, request_body: String, timeout_seconds: float) -> Dictionary:
	if _disposed:
		return {"error": LocalLlmError.create(LocalLlmError.NETWORK_ERROR, "LocalLlmRuntime is shut down.")}
	if _http_request == null or not is_instance_valid(_http_request):
		return {"error": LocalLlmError.create(LocalLlmError.UNKNOWN, "HTTPRequest is not ready.")}
	_http_request.timeout = timeout_seconds
	var headers := PackedStringArray(["Content-Type: application/json"])
	var start_error := _http_request.request(url, headers, method, request_body)
	if start_error != OK:
		return {"error": LocalLlmError.create(LocalLlmError.NETWORK_ERROR, "HTTPRequest start failed: %s" % error_string(start_error))}
	var completed: Array = await _http_request.request_completed
	var result_code: int = completed[0]
	var status_code: int = completed[1]
	var response_body: PackedByteArray = completed[3]
	if result_code != HTTPRequest.RESULT_SUCCESS:
		var technical := "HTTPRequest failed with result %d." % result_code
		return {"error": LocalLlmError.from_http_request_result(result_code, technical)}
	return {
		"status": status_code,
		"body": response_body.get_string_from_utf8(),
		"headers": completed[2],
	}


func _parse_stream_response(body: String) -> Dictionary:
	return OllamaStreamParser.parse(body)


func _parse_json(text: String) -> Dictionary:
	var parser := JSON.new()
	var parse_error := parser.parse(text)
	if parse_error != OK:
		return {"error": LocalLlmError.create(LocalLlmError.INVALID_JSON, parser.get_error_message())}
	return {"data": parser.data}


func _log_error(operation: String, error: Dictionary) -> void:
	# Не записываем тела ответов: в них могут находиться реплики игрока или внутренние инструкции.
	push_error(_format_error_log(operation, error))


func _format_error_log(operation: String, error: Dictionary) -> String:
	var endpoint := _config.get_endpoint_url() if _config != null else ""
	return "LocalLlmRuntime %s failed: kind=%s; endpoint=%s; details=%s" % [
		operation,
		error.get("kind", LocalLlmError.UNKNOWN),
		endpoint,
		error.get("technical_details", ""),
	]


func _resolve_ollama_executable() -> Dictionary:
	var executable_directory := OS.get_executable_path().get_base_dir()
	var beside_game := executable_directory.path_join("tools/ollama/ollama.exe")
	if FileAccess.file_exists(beside_game):
		return {"path": beside_game, "expected_sha256": OllamaServerControllerResource.BUNDLED_OLLAMA_SHA256}
	var project_bundle := ProjectSettings.globalize_path("res://tools/ollama/ollama.exe")
	if FileAccess.file_exists(project_bundle):
		return {"path": project_bundle, "expected_sha256": OllamaServerControllerResource.BUNDLED_OLLAMA_SHA256}
	var local_app_data := OS.get_environment("LOCALAPPDATA")
	var installed := local_app_data.path_join("Programs/Ollama/ollama.exe")
	if FileAccess.file_exists(installed):
		return {"path": installed, "expected_sha256": ""}
	# Сохраняем bundled-путь в диагностике: упаковщик помещает файл именно туда.
	return {"path": beside_game, "expected_sha256": OllamaServerControllerResource.BUNDLED_OLLAMA_SHA256}
