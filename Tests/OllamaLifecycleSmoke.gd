extends SceneTree

const LocalLlmError = preload("res://Scripts/Dialogue/LocalLlmError.gd")
const OllamaServerController = preload("res://Scripts/Dialogue/OllamaServerController.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var external := OllamaServerController.new("http://127.0.0.1:11434", "res://missing-ollama-must-not-launch.exe")
	var external_result: Dictionary = await external.ensure_server_available(Callable(self, "_external_responds"))
	_check(external_result.is_empty(), "работающий внешний endpoint переиспользуется")
	_check(not external.owns_process, "контроллер не присваивает игре внешний процесс")
	external.shutdown()

	var missing := OllamaServerController.new("http://127.0.0.1:1", "res://missing-ollama.exe", "")
	var missing_result: Dictionary = await missing.ensure_server_available(Callable(self, "_no_response"))
	_check(missing_result.error.kind == LocalLlmError.OLLAMA_EXECUTABLE_MISSING, "отсутствующий runtime получает отдельную ошибку")
	missing.shutdown()

	var checksum_path := ProjectSettings.globalize_path("res://Main.tscn")
	var checksum := OllamaServerController.new("http://127.0.0.1:1", checksum_path, "0".repeat(64))
	var checksum_result: Dictionary = await checksum.ensure_server_available(Callable(self, "_no_response"))
	_check(checksum_result.error.kind == LocalLlmError.OLLAMA_EXECUTABLE_INTEGRITY, "неверный SHA-256 блокирует запуск bundled runtime")
	checksum.shutdown()
	await _test_windows_process_tree_shutdown()
	await _test_configured_bundle_starts_and_shuts_down()

	if _failures.is_empty():
		print("PASS: Ollama lifecycle smoke")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _external_responds(_url: String, _timeout_seconds: float) -> Dictionary:
	return {"status": 404}


func _no_response(_url: String, _timeout_seconds: float) -> Dictionary:
	return {"status": 0}


func _test_windows_process_tree_shutdown() -> void:
	if OS.get_name() != "Windows":
		return

	var test_directory := OS.get_cache_dir().path_join("NpcWithLLM-lifecycle-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(test_directory)
	var script_path := test_directory.path_join("spawn-child.ps1")
	var child_pid_path := test_directory.path_join("child.pid")
	var escaped_child_pid_path := child_pid_path.replace("'", "''")
	var script_text := (
		"$child = Start-Process -FilePath \"$PSHOME\\powershell.exe\" -WindowStyle Hidden "
		+ "-ArgumentList \"-NoProfile -Command Start-Sleep -Seconds 120\" -PassThru\n"
		+ "Set-Content -LiteralPath '%s' -Value $child.Id\n" % escaped_child_pid_path
		+ "Start-Sleep -Seconds 120\n"
	)
	var script_file := FileAccess.open(script_path, FileAccess.WRITE)
	if script_file == null:
		_check(false, "lifecycle smoke создаёт временный скрипт дочернего процесса")
		return
	script_file.store_string(script_text)
	script_file.close()

	var powershell := OS.get_environment("SystemRoot").path_join("System32/WindowsPowerShell/v1.0/powershell.exe")
	var parent_pid := OS.create_process(powershell, ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script_path], false)
	if parent_pid <= 0:
		_check(false, "lifecycle smoke запускает тестовый родительский процесс")
		DirAccess.remove_absolute(script_path)
		DirAccess.remove_absolute(test_directory)
		return

	var child_pid := 0
	var deadline := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline and not FileAccess.file_exists(child_pid_path):
		await Engine.get_main_loop().create_timer(0.05).timeout
	if FileAccess.file_exists(child_pid_path):
		var pid_file := FileAccess.open(child_pid_path, FileAccess.READ)
		if pid_file != null:
			var child_pid_text := pid_file.get_as_text().strip_edges()
			if child_pid_text.is_valid_int():
				child_pid = int(child_pid_text)
			pid_file.close()

	_check(child_pid > 0, "lifecycle smoke создаёт дочерний процесс Ollama-подобного runtime")
	if child_pid > 0:
		var controller := OllamaServerController.new("http://127.0.0.1:1", "unused.exe", "")
		controller._owned_process_id = parent_pid
		controller.shutdown()
		deadline = Time.get_ticks_msec() + 5000
		while Time.get_ticks_msec() < deadline and (OS.is_process_running(parent_pid) or OS.is_process_running(child_pid)):
			await Engine.get_main_loop().create_timer(0.05).timeout
		_check(not OS.is_process_running(parent_pid), "контроллер завершает собственный Ollama-процесс")
		_check(not OS.is_process_running(child_pid), "контроллер завершает дочерний процесс Ollama")
		if OS.is_process_running(parent_pid):
			OS.execute("taskkill.exe", ["/PID", str(parent_pid), "/T", "/F"], [], true, false)
		if OS.is_process_running(child_pid):
			OS.execute("taskkill.exe", ["/PID", str(child_pid), "/T", "/F"], [], true, false)
	elif OS.is_process_running(parent_pid):
		OS.execute("taskkill.exe", ["/PID", str(parent_pid), "/T", "/F"], [], true, false)

	if FileAccess.file_exists(child_pid_path):
		DirAccess.remove_absolute(child_pid_path)
	DirAccess.remove_absolute(script_path)
	DirAccess.remove_absolute(test_directory)


func _test_configured_bundle_starts_and_shuts_down() -> void:
	var executable_path := OS.get_environment("NPC_OLLAMA_SMOKE_EXECUTABLE")
	if executable_path.is_empty():
		return
	var models_directory := OS.get_environment("NPC_OLLAMA_SMOKE_MODELS")
	var port := int(OS.get_environment("NPC_OLLAMA_SMOKE_PORT"))
	if models_directory.is_empty() or port <= 0:
		_check(false, "для реального Ollama smoke нужны model store и свободный порт")
		return

	var base_url := "http://127.0.0.1:%d" % port
	var controller := OllamaServerController.new(
		base_url,
		executable_path,
		OllamaServerController.BUNDLED_OLLAMA_SHA256,
		30.0,
		models_directory
	)
	var start_result: Dictionary = await controller.ensure_server_available(Callable(self, "_http_probe"))
	var process_id := controller.owned_process_id
	_check(start_result.is_empty(), "контроллер запускает bundled Ollama и получает HTTP-ответ")
	_check(process_id > 0, "контроллер владеет запущенным им Ollama")
	var tags_result: Dictionary = await _http_probe(base_url + "/api/tags", 5.0)
	var tags_data: Variant = JSON.parse_string(tags_result.get("body", ""))
	var configured_profile: LocalLlmConfig = load("res://LocalLlmConfig.tres")
	var configured_model_found := false
	if typeof(tags_data) == TYPE_DICTIONARY and typeof(tags_data.get("models")) == TYPE_ARRAY:
		for model in tags_data.models:
			if typeof(model) == TYPE_DICTIONARY and model.get("name", "") == configured_profile.model_name:
				configured_model_found = true
				break
	_check(configured_model_found, "bundled Ollama использует поставленный model store и видит настроенную модель")
	controller.shutdown()

	var deadline := Time.get_ticks_msec() + 5000
	var stopped_probe: Dictionary = await _http_probe(base_url + "/api/tags", 0.75)
	while Time.get_ticks_msec() < deadline and int(stopped_probe.get("status", 0)) > 0:
		await Engine.get_main_loop().create_timer(0.1).timeout
		stopped_probe = await _http_probe(base_url + "/api/tags", 0.75)
	_check(process_id > 0 and not OS.is_process_running(process_id), "игра останавливает собственный bundled Ollama")
	_check(int(stopped_probe.get("status", 0)) == 0, "после остановки порт bundled Ollama больше не отвечает")


func _http_probe(url: String, timeout_seconds: float) -> Dictionary:
	var request := HTTPRequest.new()
	root.add_child(request)
	request.timeout = timeout_seconds
	var start_error := request.request(url)
	if start_error != OK:
		request.queue_free()
		return {"status": 0}
	var completed: Array = await request.request_completed
	request.queue_free()
	if completed[0] != HTTPRequest.RESULT_SUCCESS:
		return {"status": 0}
	return {"status": int(completed[1]), "body": (completed[3] as PackedByteArray).get_string_from_utf8()}


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append("FAIL: %s" % description)
