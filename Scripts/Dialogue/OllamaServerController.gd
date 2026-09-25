class_name OllamaServerController
extends RefCounted

const BUNDLED_OLLAMA_SHA256 := "0A9D42EABC59FDAFDE8D2D3E7964F6050B31A17B3E3795BFACB367C12DF790F4"
const PROBE_TIMEOUT_SECONDS := 0.75
const POLL_INTERVAL_SECONDS := 0.25

var _base_url: String
var _executable_path: String
var _expected_sha256: String
var _models_directory: String
var _startup_timeout_seconds: float
var _owned_process_id := -1
var _server_ready := false
var _disposed := false

var owns_process: bool:
	get:
		return _is_process_running(_owned_process_id)

var owned_process_id: int:
	get:
		return _owned_process_id if owns_process else -1


func _init(
		base_url: String,
		executable_path: String,
		expected_sha256: String = BUNDLED_OLLAMA_SHA256,
		startup_timeout_seconds: float = 30.0,
		models_directory: String = ""
	) -> void:
	_base_url = base_url
	_executable_path = executable_path
	_expected_sha256 = expected_sha256
	_models_directory = models_directory
	_startup_timeout_seconds = startup_timeout_seconds


func ensure_server_available(probe_endpoint: Callable) -> Dictionary:
	if _disposed:
		return {"error": LocalLlmError.create(LocalLlmError.OLLAMA_SERVER_UNAVAILABLE, "Controller is shut down.")}
	if _server_ready:
		return {}

	var initial_probe: Dictionary = await probe_endpoint.call(_tags_url(), PROBE_TIMEOUT_SECONDS)
	if _has_http_response(initial_probe):
		# Любой ответ на endpoint означает, что процесс принадлежит внешнему запуску.
		_server_ready = true
		return {}

	if not owns_process:
		var start_result := _start_owned_process()
		if start_result.has("error"):
			return start_result

	var started_at := Time.get_ticks_msec()
	while (Time.get_ticks_msec() - started_at) / 1000.0 < _startup_timeout_seconds:
		if not owns_process:
			return {"error": LocalLlmError.create(
				LocalLlmError.OLLAMA_PROCESS_START,
				"Bundled Ollama exited before serving HTTP."
			)}
		var probe: Dictionary = await probe_endpoint.call(_tags_url(), PROBE_TIMEOUT_SECONDS)
		if _has_http_response(probe):
			_server_ready = true
			return {}
		await Engine.get_main_loop().create_timer(POLL_INTERVAL_SECONDS).timeout

	return {"error": LocalLlmError.create(
		LocalLlmError.OLLAMA_SERVER_UNAVAILABLE,
		"Ollama did not answer at %s within %.0f seconds." % [_base_url, _startup_timeout_seconds]
	)}


func mark_server_unavailable() -> void:
	_server_ready = false


func stop_owned_process() -> void:
	var process_id := _owned_process_id
	_owned_process_id = -1
	if process_id > 0:
		_server_ready = false
		if OS.is_process_running(process_id):
			if OS.get_name() == "Windows":
				var output: Array = []
				var exit_code := OS.execute("taskkill.exe", ["/PID", str(process_id), "/T", "/F"], output, true, false)
				if exit_code != 0 and OS.is_process_running(process_id):
					push_warning("Не удалось остановить дерево процессов Ollama, PID %d: %s" % [process_id, output])
			else:
				var error := OS.kill(process_id)
				if error != OK:
					push_warning("Не удалось остановить запущенный игрой Ollama, PID %d: %s" % [process_id, error])


func shutdown() -> void:
	if _disposed:
		return
	_disposed = true
	stop_owned_process()


func _start_owned_process() -> Dictionary:
	if not _is_loopback_url(_base_url):
		return {"error": LocalLlmError.create(
			LocalLlmError.CONFIGURATION,
			"Bundled Ollama can only serve a loopback HTTP(S) URL."
		)}

	var full_path := _executable_path
	if full_path.begins_with("res://"):
		full_path = ProjectSettings.globalize_path(full_path)
	full_path = full_path.simplify_path()
	if not FileAccess.file_exists(full_path):
		return {"error": LocalLlmError.create(
			LocalLlmError.OLLAMA_EXECUTABLE_MISSING,
			"Bundled Ollama executable not found: %s" % full_path
		)}

	if not _expected_sha256.is_empty():
		var actual_sha256 := FileAccess.get_sha256(full_path).to_upper()
		if actual_sha256.is_empty():
			return {"error": LocalLlmError.create(
				LocalLlmError.OLLAMA_EXECUTABLE_INTEGRITY,
				"Could not read bundled Ollama executable SHA-256."
			)}
		if actual_sha256 != _expected_sha256.to_upper():
			return {"error": LocalLlmError.create(
				LocalLlmError.OLLAMA_EXECUTABLE_INTEGRITY,
				"Bundled Ollama SHA-256 mismatch. Expected %s; got %s." % [_expected_sha256, actual_sha256]
			)}

	var endpoint := _parse_endpoint()
	if endpoint.is_empty():
		return {"error": LocalLlmError.create(LocalLlmError.CONFIGURATION, "Invalid Ollama endpoint URL.")}
	var host: String = endpoint.host
	var endpoint_port: int = endpoint.port
	if endpoint_port > 0:
		host += ":%d" % endpoint_port

	var previous_host := OS.get_environment("OLLAMA_HOST")
	var had_host := OS.has_environment("OLLAMA_HOST")
	var previous_models := OS.get_environment("OLLAMA_MODELS")
	var had_models := OS.has_environment("OLLAMA_MODELS")
	OS.set_environment("OLLAMA_HOST", host)
	if not _models_directory.is_empty() and DirAccess.dir_exists_absolute(_models_directory):
		OS.set_environment("OLLAMA_MODELS", _models_directory)
	var process_id := OS.create_process(full_path, ["serve"], false)
	_restore_environment("OLLAMA_HOST", had_host, previous_host)
	_restore_environment("OLLAMA_MODELS", had_models, previous_models)
	if process_id <= 0:
		return {"error": LocalLlmError.create(
			LocalLlmError.OLLAMA_PROCESS_START,
			"OS.create_process failed for bundled Ollama: %s" % full_path
		)}
	_owned_process_id = process_id
	return {}


func _parse_endpoint() -> Dictionary:
	var expression := RegEx.new()
	expression.compile("^https?://(\\[[0-9A-Fa-f:]+\\]|[^/:?#]+)(?::([0-9]{1,5}))?(?:/.*)?$")
	var found := expression.search(_base_url.strip_edges())
	if not found:
		return {}
	var host: String = found.get_string(1).trim_prefix("[").trim_suffix("]")
	var port: int = int(found.get_string(2)) if not found.get_string(2).is_empty() else 0
	return {"host": host, "port": port}


func _tags_url() -> String:
	return _base_url.strip_edges().trim_suffix("/") + "/api/tags"


func _has_http_response(result: Dictionary) -> bool:
	return int(result.get("status", 0)) > 0


func _is_loopback_url(url: String) -> bool:
	var expression := RegEx.new()
	expression.compile("^https?://(\\[[0-9A-Fa-f:]+\\]|[^/:?#]+)(?::[0-9]{1,5})?(?:/.*)?$")
	var found := expression.search(url.strip_edges())
	if not found:
		return false
	var host := found.get_string(1).to_lower()
	return host == "localhost" or host == "127.0.0.1" or host.begins_with("127.") or host == "[::1]"


func _is_process_running(process_id: int) -> bool:
	return process_id > 0 and OS.is_process_running(process_id)


func _restore_environment(variable: String, was_defined: bool, previous_value: String) -> void:
	if was_defined:
		OS.set_environment(variable, previous_value)
	else:
		OS.unset_environment(variable)
