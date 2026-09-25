class_name ChatResponder
extends Node

signal response_started
signal response_chunk_received(text: String)
signal response_emotion_received(emotion: String)
signal preparation_started
signal preparation_finished
signal response_received(response: String)
signal response_failed(error: String)

@export var profile: NpcProfile

var active_profile: NpcProfile:
	get:
		return get_active_profile()

var is_busy := false


func prepare() -> void:
	preparation_finished.emit()


func get_active_profile() -> NpcProfile:
	return profile


func request_response(_message: String) -> void:
	push_error("ChatResponder.request_response must be implemented by an adapter.")
