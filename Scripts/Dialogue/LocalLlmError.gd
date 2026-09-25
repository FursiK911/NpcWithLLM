class_name LocalLlmError
extends RefCounted

const CONFIGURATION := "Configuration"
const HTTP_ERROR := "HttpError"
const NETWORK_ERROR := "NetworkError"
const TIMEOUT := "Timeout"
const INVALID_JSON := "InvalidJson"
const EMPTY_RESPONSE := "EmptyResponse"
const INCOMPLETE_RESPONSE := "IncompleteResponse"
const OLLAMA_EXECUTABLE_MISSING := "OllamaExecutableMissing"
const OLLAMA_EXECUTABLE_INTEGRITY := "OllamaExecutableIntegrity"
const OLLAMA_PROCESS_START := "OllamaProcessStart"
const OLLAMA_SERVER_UNAVAILABLE := "OllamaServerUnavailable"
const MODEL_UNAVAILABLE := "ModelUnavailable"
const UNKNOWN := "Unknown"

const USER_MESSAGES := {
	CONFIGURATION: "Неверно настроено подключение к локальной модели.",
	HTTP_ERROR: "Сервис локальной модели вернул ошибку HTTP.",
	NETWORK_ERROR: "Не удалось подключиться к локальному сервису модели. Проверьте, запущен ли он.",
	TIMEOUT: "Локальная модель не ответила вовремя. Попробуйте ещё раз.",
	INVALID_JSON: "Локальная модель вернула ответ неожиданного формата.",
	EMPTY_RESPONSE: "Локальная модель вернула пустой ответ.",
	INCOMPLETE_RESPONSE: "Ответ персонажа оборвался. Попробуйте ещё раз.",
	OLLAMA_EXECUTABLE_MISSING: "Не найден локальный runtime Ollama. Восстановите файлы поставки.",
	OLLAMA_EXECUTABLE_INTEGRITY: "Файл Ollama повреждён или изменён. Восстановите файл поставки.",
	OLLAMA_PROCESS_START: "Не удалось запустить локальный сервис Ollama.",
	OLLAMA_SERVER_UNAVAILABLE: "Локальный сервис Ollama не запустился вовремя.",
	MODEL_UNAVAILABLE: "Запрошенная модель не найдена в локальной Ollama.",
	UNKNOWN: "Не удалось получить ответ от локальной модели.",
}


static func create(kind: String, technical_details: String = "") -> Dictionary:
	return {
		"kind": kind,
		"user_message": USER_MESSAGES.get(kind, USER_MESSAGES[UNKNOWN]),
		"technical_details": technical_details,
	}


static func model_unavailable(model_name: String) -> Dictionary:
	var configured_name := model_name if not model_name.strip_edges().is_empty() else "(не указана)"
	return {
		"kind": MODEL_UNAVAILABLE,
		"user_message": "Модель «%s» не найдена в локальной Ollama. Установите её и повторите запуск." % configured_name,
		"technical_details": "Configured model '%s' is not present in the local Ollama model list." % configured_name,
	}


static func from_http_request_result(result_code: int, technical_details: String) -> Dictionary:
	if result_code == HTTPRequest.RESULT_SUCCESS:
		return {}
	var kind := NETWORK_ERROR
	if result_code == HTTPRequest.RESULT_TIMEOUT:
		kind = TIMEOUT
	return create(kind, technical_details)
