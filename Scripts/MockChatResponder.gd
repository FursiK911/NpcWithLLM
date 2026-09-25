class_name MockChatResponder
extends ChatResponder

const RESPONSE_DELAY_SECONDS := 0.8
const FAILURE_TRIGGER := "/fail"


func request_response(message: String) -> void:
	if is_busy:
		return

	is_busy = true
	response_started.emit()
	_respond_after_delay(message)


func _respond_after_delay(message: String) -> void:
	await get_tree().create_timer(RESPONSE_DELAY_SECONDS).timeout
	if message.to_lower() == FAILURE_TRIGGER:
		response_failed.emit("Тестовая ошибка провайдера.")
	else:
		response_emotion_received.emit("neutral")
		var response := "Персонаж услышал: «%s»" % message
		response_chunk_received.emit(response)
		response_received.emit(response)
	is_busy = false
