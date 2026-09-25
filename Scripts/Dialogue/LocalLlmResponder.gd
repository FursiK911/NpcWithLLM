class_name LocalLlmResponder
extends ChatResponder

@export var config: LocalLlmConfig

var memory := NpcMemory.new()
var _context_builder := ContextBuilder.new()
var _history: DialogueHistory
var _runtime: Object
var _profile_override: NpcProfile
var _prepared := false
var _shutting_down := false

var history: DialogueHistory:
	get:
		if _history == null:
			var limits := config if config != null else LocalLlmConfig.new()
			_history = DialogueHistory.new(limits.max_history_messages, limits.max_history_characters)
		return _history


func _exit_tree() -> void:
	_shutting_down = true
	if _runtime != null and _runtime.has_method("shutdown"):
		_runtime.shutdown()


func prepare() -> void:
	if is_busy:
		return
	is_busy = true
	preparation_started.emit()
	_prepare_runtime_async()


func request_response(message: String) -> void:
	if is_busy or message.strip_edges().is_empty():
		return
	is_busy = true
	response_started.emit()
	_generate_response_async(message.strip_edges())


func configure(runtime: Object, profile_resource: NpcProfile) -> void:
	_runtime = runtime
	_profile_override = profile_resource
	if _runtime is Node and _runtime.get_parent() == null:
		add_child(_runtime)
	if _runtime.has_method("configure"):
		_runtime.configure(config if config != null else LocalLlmConfig.new())


func get_active_profile() -> NpcProfile:
	return _profile_override if _profile_override != null else profile


func _prepare_runtime_async() -> void:
	var result: Dictionary = await _get_runtime().prepare_async()
	if _shutting_down:
		return
	is_busy = false
	if result.has("error"):
		_report_failure(result.error)
		return
	_prepared = true
	preparation_finished.emit()


func _generate_response_async(message: String) -> void:
	var runtime := _get_runtime()
	if not _prepared:
		var preparation: Dictionary = await runtime.prepare_async()
		if preparation.has("error"):
			_finish_failure(preparation.error)
			return
		_prepared = true
	if _shutting_down:
		return

	var npc_profile := active_profile
	if npc_profile == null:
		_finish_failure(LocalLlmError.create(
			LocalLlmError.CONFIGURATION,
			"Персонажу не назначен профиль: узел ChatResponder должен ссылаться на res://NpcProfile.tres."
		))
		return
	var persona := npc_profile.to_persona()
	if not persona.is_valid():
		_finish_failure(LocalLlmError.create(LocalLlmError.CONFIGURATION, "NpcProfile contains an empty persona field."))
		return

	var messages := _context_builder.build(persona, npc_profile.situation, memory, history, message)
	var generated: Dictionary = await runtime.generate_async(messages)
	if _shutting_down:
		return
	if generated.has("error"):
		_finish_failure(generated.error)
		return

	var parsed := GeneratedCharacterResponse.parse(generated.get("raw_response", ""))
	if parsed.has("error"):
		_finish_failure(parsed.error)
		return

	var response: GeneratedCharacterResponse = parsed.response
	# Состояние меняется только после успешной генерации и проверки структурированного ответа.
	memory.learn_from(message)
	history.add_pair(message, response.message)
	is_busy = false
	response_emotion_received.emit(response.emotion)
	response_chunk_received.emit(response.message)
	response_received.emit(response.message)


func _finish_failure(error: Dictionary) -> void:
	is_busy = false
	_report_failure(error)


func _report_failure(error: Dictionary) -> void:
	if _shutting_down:
		return
	response_failed.emit(error.get("user_message", "Не удалось получить ответ от локальной модели."))


func _get_runtime() -> Object:
	if _runtime == null:
		_runtime = LocalLlmRuntime.new()
		_runtime.configure(config if config != null else LocalLlmConfig.new())
		add_child(_runtime)
	return _runtime


static func default_profile() -> NpcProfile:
	var result := NpcProfile.new()
	result.npc_name = "Иван"
	result.role = "механик в мастерской"
	result.character = "наблюдательный и практичный"
	result.speech_style = "короткие спокойные фразы"
	result.player_attitude = "настороженно, но разговаривает"
	result.knowledge = "знает мастерскую; не знает, кто вошедший"
	result.behavior_constraints = "не выдумывает факты о мире"
	result.situation = "Иван в мастерской."
	return result
