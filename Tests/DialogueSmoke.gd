extends Node


class FakeLocalLlmRuntime extends RefCounted:
	signal release_request

	var responses: Array[Dictionary] = []
	var pause_next_response := false
	var captured_context: Array[DialogueMessage] = []
	var preparation_calls := 0


	func prepare_async() -> Dictionary:
		preparation_calls += 1
		return {}


	func generate_async(context: Array[DialogueMessage]) -> Dictionary:
		captured_context = context.duplicate()
		if pause_next_response:
			pause_next_response = false
			await release_request
		return responses.pop_front()


var _failures: Array[String] = []
var _main: Node


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://Main.tscn")
	_main = scene.instantiate()
	var responder: LocalLlmResponder = _main.get_node("ChatResponder")
	var fake := FakeLocalLlmRuntime.new()
	fake.responses = [
		{"raw_response": "{\"message\":\"Здравствуй, Алекс.\",\"emotion\":\"happy\"}"},
		{"error": LocalLlmError.create(LocalLlmError.TIMEOUT, "test timeout")},
		{"raw_response": "не JSON"},
	]
	fake.pause_next_response = true
	responder.configure(fake, responder.profile)
	add_child(_main)
	await get_tree().process_frame

	var input: TextEdit = _main.get_node("UiLayer/DialoguePanel/Margin/VBox/Input/MessageInput")
	var send_button: Button = _main.get_node("UiLayer/DialoguePanel/Margin/VBox/Input/SendButton")
	var response_text: RichTextLabel = _main.get_node("UiLayer/DialoguePanel/Margin/VBox/ResponseScroll/ResponseText")
	var intro_button: Button = _main.get_node("UiLayer/IntroOverlay/CenterContainer/IntroPanel/Margin/VBox/OkRow/IntroOkButton")
	var portrait: TextureRect = _main.get_node("UiLayer/MechanicPortrait")
	intro_button.pressed.emit()
	await get_tree().process_frame
	_check(fake.preparation_calls == 1, "экран готовит адаптер до диалога")
	_check(input.editable and not send_button.disabled, "ввод включается после вступления и подготовки")

	input.text = "Меня зовут Алекс. Я работаю механиком."
	send_button.pressed.emit()
	await get_tree().process_frame
	_check(send_button.disabled, "кнопка отправки заблокирована во время ожидания")
	_check(not fake.captured_context.is_empty() and fake.captured_context.back().content == "Меня зовут Алекс. Я работаю механиком.", "текущая реплика передана адаптеру")
	fake.release_request.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(response_text.text == "Здравствуй, Алекс.", "UI показывает только поле message из JSON")
	_check(input.text.is_empty(), "успех очищает поле ввода")
	_check(responder.memory.player_name == "Алекс", "успешная реплика обновляет память игрока")
	_check(responder.memory.player_profession == "механиком", "успешная реплика обновляет профессию игрока")
	_check(responder.history.message_count == 2, "успешная пара попадает в историю")
	_check(portrait.texture.resource_path.ends_with("happy.png"), "эмоция выбирает соответствующий портрет")

	input.text = "Не забудь это сообщение."
	send_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(input.text == "Не забудь это сообщение.", "ошибка сохраняет введённое сообщение")
	_check(responder.history.message_count == 2, "ошибка не меняет историю")
	_check(portrait.texture.resource_path.ends_with("happy.png"), "ошибка возвращает портрет до запроса")
	_check(not send_button.disabled, "после ошибки доступен ручной повтор")

	input.text = "Меня зовут Борис."
	send_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(responder.history.message_count == 2, "некорректный JSON не добавляется в историю")
	_check(responder.memory.player_name == "Алекс", "некорректный JSON не меняет память")
	_check(input.text == "Меня зовут Борис.", "ошибка разбора JSON сохраняет ввод")

	_main.queue_free()
	if _failures.is_empty():
		print("PASS: DialogueSmoke")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append("FAIL: %s" % description)
