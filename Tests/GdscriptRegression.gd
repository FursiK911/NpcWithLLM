extends SceneTree

const DialogueHistory = preload("res://Scripts/Dialogue/DialogueHistory.gd")
const ContextBuilder = preload("res://Scripts/Dialogue/ContextBuilder.gd")
const DialogueMessage = preload("res://Scripts/Dialogue/DialogueMessage.gd")
const GeneratedCharacterResponse = preload("res://Scripts/Dialogue/GeneratedCharacterResponse.gd")
const LocalLlmConfig = preload("res://Scripts/Dialogue/LocalLlmConfig.gd")
const LocalLlmError = preload("res://Scripts/Dialogue/LocalLlmError.gd")
const LocalLlmRequestBuilder = preload("res://Scripts/Dialogue/LocalLlmRequestBuilder.gd")
const LocalLlmRuntime = preload("res://Scripts/Dialogue/LocalLlmRuntime.gd")
const NpcMemory = preload("res://Scripts/Dialogue/NpcMemory.gd")
const NpcPersona = preload("res://Scripts/Dialogue/NpcPersona.gd")
const OllamaServerController = preload("res://Scripts/Dialogue/OllamaServerController.gd")
const OllamaStreamParser = preload("res://Scripts/Dialogue/OllamaStreamParser.gd")

class FakeOllamaHttpServer:
	extends Node

	var _server := TCPServer.new()
	var _clients: Array[Dictionary] = []
	var port := 0
	var tags_request_count := 0
	var available_model_name := "fixture-model:latest"
	var chat_request_count := 0
	var chat_request_body := ""

	func start() -> Error:
		var result := _server.listen(0, "127.0.0.1")
		if result == OK:
			port = _server.get_local_port()
		set_process(result == OK)
		return result

	func _process(_delta: float) -> void:
		while _server.is_connection_available():
			_clients.append({"peer": _server.take_connection(), "buffer": PackedByteArray()})

		var pending: Array[Dictionary] = []
		for client in _clients:
			var peer: StreamPeerTCP = client.peer
			peer.poll()
			var available := peer.get_available_bytes()
			if available > 0:
				var received: Array = peer.get_data(available)
				if received[0] == OK:
					client.buffer.append_array(received[1])

			var request_text: String = client.buffer.get_string_from_utf8()
			var separator := request_text.find("\r\n\r\n")
			if separator >= 0:
				var header_text := request_text.substr(0, separator)
				var expected_body_bytes := 0
				for header_line in header_text.split("\r\n"):
					if header_line.to_lower().begins_with("content-length:"):
						expected_body_bytes = int(header_line.get_slice(":", 1).strip_edges())
				var body := request_text.substr(separator + 4)
				if body.to_utf8_buffer().size() >= expected_body_bytes:
					var body_start_bytes := header_text.to_utf8_buffer().size() + 4
					var body_bytes: PackedByteArray = client.buffer.slice(body_start_bytes, body_start_bytes + expected_body_bytes)
					_respond(peer, header_text, body_bytes.get_string_from_utf8())
					continue
			if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
				pending.append(client)
		_clients = pending

	func _respond(peer: StreamPeerTCP, header_text: String, body: String) -> void:
		var request_line := header_text.get_slice("\r\n", 0)
		var request_parts := request_line.split(" ")
		var response_body: String
		if request_parts.size() >= 2 and request_parts[0] == "GET" and request_parts[1] == "/api/tags":
			tags_request_count += 1
			var models: Array[Dictionary] = []
			if not available_model_name.is_empty():
				models.append({"name": available_model_name})
			response_body = JSON.stringify({"models": models})
		elif request_parts.size() >= 2 and request_parts[0] == "POST" and request_parts[1] == "/api/chat":
			chat_request_count += 1
			chat_request_body = body
			var generated_json := JSON.stringify({"message": "Привет из GDScript runtime.", "emotion": "happy"})
			response_body = JSON.stringify({
				"message": {"content": generated_json},
				"done": true,
				"done_reason": "stop",
			}) + "\n"
		else:
			response_body = JSON.stringify({"error": "unexpected fake request"})
		var response := "HTTP/1.1 200 OK\r\nContent-Type: application/x-ndjson\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" % [
			response_body.to_utf8_buffer().size(),
			response_body,
		]
		peer.put_data(response.to_utf8_buffer())
		peer.disconnect_from_host()

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_memory_extracts_name_and_profession()
	_test_memory_ignores_non_profession_phrases()
	_test_memory_formats_empty_and_learned_facts()
	_test_history_keeps_recent_complete_pairs()
	_test_history_honours_message_and_character_limits()
	_test_context_uses_persona_memory_history_and_current_message_in_order()
	_test_request_uses_the_selected_ollama_model_and_json_schema()
	_test_structured_response_is_validated()
	_test_configuration_keeps_the_local_endpoint_and_model()
	_test_ollama_stream_is_assembled_and_errors_are_reported()
	_test_http_errors_keep_timeout_and_connection_kinds()
	_test_technical_error_log_keeps_endpoint_and_details()
	await _test_runtime_http_path()
	await _test_ollama_lifecycle_reuses_external_endpoint_and_checks_bundle()

	if _failures.is_empty():
		print("PASS: GDScript regression checks")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_memory_extracts_name_and_profession() -> void:
	var memory = NpcMemory.new()
	memory.learn_from("Меня зовут Дмитрий.")
	memory.learn_from("Я работаю программистом.")
	_check(memory.player_name == "Дмитрий", "память сохраняет имя игрока")
	_check(memory.player_profession == "программистом", "память сохраняет профессию игрока")


func _test_memory_ignores_non_profession_phrases() -> void:
	var memory = NpcMemory.new()
	memory.learn_from("Я впервые в этом городе.")
	_check(memory.player_profession.is_empty(), "обычная фраза не становится профессией")
	memory.learn_from("Я работаю программистом.")
	memory.learn_from("Я слышал странный стук.")
	_check(memory.player_profession == "программистом", "обычная фраза не затирает найденную профессию")


func _test_memory_formats_empty_and_learned_facts() -> void:
	var memory = NpcMemory.new()
	_check(memory.to_context_text() == "Пока нет сохранённых фактов о игроке.", "пустая память сохраняет прежнее описание")
	memory.learn_from("Моё имя Алекс.")
	_check(memory.to_context_text() == "имя игрока: Алекс", "имя попадает в контекст памяти")
	memory.learn_from("МОЁ ИМЯ Мария!")
	_check(memory.player_name == "Мария", "память распознаёт имя без учёта регистра")


func _test_history_keeps_recent_complete_pairs() -> void:
	var history = DialogueHistory.new()
	for turn in range(1, 26):
		history.add_pair("ход %d" % turn, "ответ %d" % turn)
	_check(history.message_count == 32, "история ограничивает количество сообщений")
	_check(history.messages[0].content == "ход 10", "история удаляет старые полные пары")
	_check(history.messages[31].content == "ответ 25", "история сохраняет последнюю реплику")


func _test_history_honours_message_and_character_limits() -> void:
	var by_messages = DialogueHistory.new(4, 8000)
	for turn in range(1, 6):
		by_messages.add_pair("ход %d" % turn, "ответ %d" % turn)
	_check(by_messages.message_count == 4, "настраиваемый лимит сообщений соблюдается")
	_check(by_messages.messages[0].content == "ход 4", "лимит сообщений удаляет старую пару")

	var by_characters = DialogueHistory.new(32, 40)
	for turn in range(4):
		by_characters.add_pair("с".repeat(30), "с".repeat(30))
	_check(by_characters.character_count <= 40, "настраиваемый лимит символов соблюдается")


func _test_context_uses_persona_memory_history_and_current_message_in_order() -> void:
	var persona = NpcPersona.new(
		"Иван", "механик", "практичный", "коротко", "настороженно", "не знает, кто вошедший", "не выдумывает факты"
	)
	var memory = NpcMemory.new()
	memory.learn_from("Меня зовут Дмитрий.")
	var history = DialogueHistory.new()
	history.add_pair("Сначала я поздоровался.", "Иван ответил.")
	var context = ContextBuilder.new().build(persona, "Иван в мастерской.", memory, history, "Как меня зовут?")
	_check(context.size() == 4, "контекст содержит систему, историю и новое сообщение")
	_check(context[0].role == "system", "инструкции персонажа идут первыми")
	_check(context[0].content.contains("имя игрока: Дмитрий"), "контекст содержит отдельную память")
	_check(context[0].content.contains("Known scene facts:\nИван в мастерской."), "контекст содержит ситуацию персонажа")
	_check(context[1].role == "user" and context[1].content == "Сначала я поздоровался.", "история сохраняет роль игрока")
	_check(context[2].role == "assistant" and context[2].content == "Иван ответил.", "история сохраняет ответ персонажа")
	_check(context[3].role == "user" and context[3].content == "Как меня зовут?", "текущая реплика идёт последней")


func _test_request_uses_the_selected_ollama_model_and_json_schema() -> void:
	var messages: Array[DialogueMessage] = [
		DialogueMessage.new("system", "Ты — Иван."),
		DialogueMessage.new("user", "Привет."),
	]
	var result = LocalLlmRequestBuilder.create("qwen35-9b-q4km-bartowski:latest", messages, 0.7, 0.8, 256, false, true, 8192, 0.0)
	var payload: Dictionary = result.payload
	_check(payload.model == "qwen35-9b-q4km-bartowski:latest", "запрос использует выбранную модель")
	_check(payload.stream and not payload.think, "запрос сохраняет режим Ollama")
	_check(payload.messages[0].role == "system" and payload.messages[1].role == "user", "система предшествует реплике игрока")
	_check(payload.options.top_p == 0.8 and payload.options.num_predict == 256, "параметры генерации сохраняются")
	_check(payload.options.num_ctx == 8192 and payload.options.repeat_penalty == 1.0, "параметры контекста сохраняются")
	_check(payload.format.required == ["message", "emotion"], "модель должна вернуть message и emotion в JSON")


func _test_structured_response_is_validated() -> void:
	var valid = GeneratedCharacterResponse.parse("{\"message\":\"Привет.\",\"emotion\":\"happy\"}")
	_check(not valid.has("error"), "валидный JSON принимается")
	_check(valid.response.message == "Привет." and valid.response.emotion == "happy", "извлекаются реплика и эмоция")
	var fallback = GeneratedCharacterResponse.parse("{\"message\":\"Спокойно.\",\"emotion\":\"unknown\"}")
	_check(fallback.response.emotion == "neutral", "неизвестная эмоция заменяется на neutral")
	_check(GeneratedCharacterResponse.parse("не JSON").error.kind == "InvalidJson", "некорректный JSON считается ошибкой")
	_check(GeneratedCharacterResponse.parse("{\"message\":\" \"}").error.kind == "EmptyResponse", "пустое поле message считается ошибкой")


func _test_configuration_keeps_the_local_endpoint_and_model() -> void:
	var config = LocalLlmConfig.new()
	_check(config.validate_configuration().is_empty(), "конфигурация по умолчанию корректна")
	_check(config.get_endpoint_url() == "http://127.0.0.1:11434/api/chat", "endpoint Ollama не меняется")
	_check(config.model_name == "qwen35-9b-q4km-bartowski:latest", "модель проекта не меняется")
	config.base_url = "https://example.com"
	_check(config.validate_configuration().kind == "Configuration", "удалённый endpoint не принимается")


func _test_ollama_stream_is_assembled_and_errors_are_reported() -> void:
	var chunks := "\n".join(PackedStringArray([
		JSON.stringify({"message": {"content": "{\"message\":\"Здравствуй, "}, "done": false}),
		JSON.stringify({"message": {"content": "друг.\",\"emotion\":\"happy\"}"}, "done": false}),
		JSON.stringify({"message": {"content": ""}, "done": true, "done_reason": "stop"}),
	]))
	var parsed := OllamaStreamParser.parse(chunks)
	_check(parsed.has("raw_response"), "поток Ollama разбирается: %s" % str(parsed))
	if parsed.has("raw_response"):
		_check(parsed.raw_response == "{\"message\":\"Здравствуй, друг.\",\"emotion\":\"happy\"}", "поток Ollama собирается в исходный JSON-ответ")
		_check(GeneratedCharacterResponse.parse(parsed.raw_response).response.message == "Здравствуй, друг.", "собранный ответ передаётся JSON-парсеру персонажа")
	var truncated := OllamaStreamParser.parse("{\"message\":{\"content\":\"часть\"},\"done\":false}")
	_check(truncated.error.kind == LocalLlmError.INCOMPLETE_RESPONSE, "оборванный поток считается неполным ответом")
	var limited := OllamaStreamParser.parse("{\"message\":{\"content\":\"часть\"},\"done\":true,\"done_reason\":\"length\"}")
	_check(limited.error.kind == LocalLlmError.INCOMPLETE_RESPONSE, "достигнутый лимит генерации сохраняет ошибку усечения")


func _test_http_errors_keep_timeout_and_connection_kinds() -> void:
	var timeout := LocalLlmError.from_http_request_result(HTTPRequest.RESULT_TIMEOUT, "timed out")
	var connection := LocalLlmError.from_http_request_result(HTTPRequest.RESULT_CANT_CONNECT, "connection failed")
	_check(timeout.kind == LocalLlmError.TIMEOUT, "HTTP timeout распознаётся отдельно")
	_check(connection.kind == LocalLlmError.NETWORK_ERROR, "сетевая ошибка сохраняет свой тип")
	_check(timeout.user_message.contains("Попробуйте ещё раз"), "игрок получает прежнее сообщение о timeout")


func _test_technical_error_log_keeps_endpoint_and_details() -> void:
	var runtime = LocalLlmRuntime.new()
	runtime._config = LocalLlmConfig.new()
	var log_entry: String = runtime._format_error_log("generation", LocalLlmError.create(LocalLlmError.HTTP_ERROR, "HTTP 500"))
	_check(log_entry.contains("endpoint=http://127.0.0.1:11434/api/chat"), "технический лог сохраняет endpoint запроса")
	_check(log_entry.contains("details=HTTP 500"), "технический лог сохраняет причину ошибки")
	runtime.free()


func _test_runtime_http_path() -> void:
	var fake_server := FakeOllamaHttpServer.new()
	root.add_child(fake_server)
	var listen_result: Error = fake_server.start()
	_check(listen_result == OK and fake_server.port > 0, "тестовый Ollama HTTP endpoint запускается")
	if listen_result != OK or fake_server.port <= 0:
		fake_server.queue_free()
		return

	var config := LocalLlmConfig.new()
	config.base_url = "http://127.0.0.1:%d" % fake_server.port
	config.model_name = "fixture-model:latest"
	config.timeout_seconds = 5.0
	var runtime := LocalLlmRuntime.new()
	root.add_child(runtime)
	runtime.configure(config)
	var prepare_result: Dictionary = await runtime.prepare_async()
	_check(prepare_result.is_empty(), "prepare_async проверяет endpoint и наличие выбранной модели")
	_check(fake_server.tags_request_count == 2, "подготовка runtime запрашивает endpoint и список моделей Ollama")
	_check(fake_server.chat_request_count == 1, "подготовка runtime выполняет один warm-up POST")

	var context: Array[DialogueMessage] = [
		DialogueMessage.new("system", "Ты — тестовый персонаж."),
		DialogueMessage.new("user", "Привет."),
	]
	var result: Dictionary = await runtime.generate_async(context)
	_check(not result.has("error"), "LocalLlmRuntime выполняет HTTP-запрос и разбирает NDJSON: %s" % str(result))
	_check(fake_server.tags_request_count == 2, "runtime проверяет локальный Ollama endpoint через HTTPRequest")
	_check(fake_server.chat_request_count == 2, "обычная генерация выполняет второй POST после warm-up")
	var request_payload: Variant = JSON.parse_string(fake_server.chat_request_body)
	_check(typeof(request_payload) == TYPE_DICTIONARY, "runtime отправляет тело запроса Ollama")
	if typeof(request_payload) == TYPE_DICTIONARY:
		_check(request_payload.get("model", "") == config.model_name, "HTTP-запрос runtime сохраняет выбранную модель")
		_check(request_payload.get("stream", false) and not request_payload.get("think", true), "HTTP-запрос runtime сохраняет stream и think настройки")
		_check(request_payload.get("format", {}).get("required", []) == ["message", "emotion"], "HTTP-запрос runtime передаёт JSON schema")
		_check(request_payload.get("messages", []).size() == 2, "HTTP-запрос runtime передаёт историю контекста")
	if result.has("raw_response"):
		var parsed := GeneratedCharacterResponse.parse(result.raw_response)
		_check(not parsed.has("error") and parsed.response.message == "Привет из GDScript runtime.", "GDScript HTTP-ответ проходит до структурированного ответа персонажа")
	fake_server.available_model_name = ""
	var missing_model_result: Dictionary = await runtime.prepare_async()
	_check(missing_model_result.get("error", {}).get("kind", "") == LocalLlmError.MODEL_UNAVAILABLE, "prepare_async сообщает об отсутствующем теге выбранной модели")
	runtime.queue_free()
	fake_server.queue_free()
	await process_frame


func _test_ollama_lifecycle_reuses_external_endpoint_and_checks_bundle() -> void:
	var external := OllamaServerController.new("http://127.0.0.1:11434", "res://missing-ollama.exe")
	var external_result: Dictionary = await external.ensure_server_available(Callable(self, "_fake_http_response"))
	_check(external_result.is_empty(), "отвечающий локальный endpoint переиспользуется")
	_check(not external.owns_process, "внешний процесс не присваивается игре")
	external.shutdown()

	var missing := OllamaServerController.new("http://127.0.0.1:1", "res://missing-ollama.exe", "")
	var missing_result: Dictionary = await missing.ensure_server_available(Callable(self, "_fake_no_response"))
	_check(missing_result.error.kind == LocalLlmError.OLLAMA_EXECUTABLE_MISSING, "отсутствующий bundled Ollama выдаёт отдельную ошибку")
	missing.shutdown()

	var mismatched := OllamaServerController.new("http://127.0.0.1:1", ProjectSettings.globalize_path("res://Main.tscn"), "0".repeat(64))
	var checksum_result: Dictionary = await mismatched.ensure_server_available(Callable(self, "_fake_no_response"))
	_check(checksum_result.error.kind == LocalLlmError.OLLAMA_EXECUTABLE_INTEGRITY, "bundled Ollama с неверным SHA-256 не запускается")
	mismatched.shutdown()


func _fake_http_response(_url: String, _timeout: float) -> Dictionary:
	return {"status": 404}


func _fake_no_response(_url: String, _timeout: float) -> Dictionary:
	return {"status": 0}


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append("FAIL: %s" % description)
