extends Node2D

const ANGRY_PORTRAIT := "res://Art/Mechanic/angry.png"
const HAPPY_PORTRAIT := "res://Art/Mechanic/happy.png"
const IDLE_PORTRAIT := "res://Art/Mechanic/idle.png"
const SAD_PORTRAIT := "res://Art/Mechanic/sad.png"
const THINKING_PORTRAIT := "res://Art/Mechanic/thinking.png"
const SPEAKING_PORTRAITS := [
	"res://Art/Mechanic/speak_1.png",
	"res://Art/Mechanic/speak_2.png",
	"res://Art/Mechanic/speak_3.png",
	"res://Art/Mechanic/speak_4.png",
	"res://Art/Mechanic/speak_5.png",
]

@onready var _chat_responder: ChatResponder = $ChatResponder
@onready var _message_input: TextEdit = $UiLayer/DialoguePanel/Margin/VBox/Input/MessageInput
@onready var _send_button: Button = $UiLayer/DialoguePanel/Margin/VBox/Input/SendButton
@onready var _response_text: RichTextLabel = $UiLayer/DialoguePanel/Margin/VBox/ResponseScroll/ResponseText
@onready var _status_label: Label = $UiLayer/DialoguePanel/Margin/VBox/StatusLabel
@onready var _preparation_panel: Control = $UiLayer/PreparationPanel
@onready var _preparation_status_label: Label = $UiLayer/PreparationPanel/Margin/VBox/PreparationStatusLabel
@onready var _preparation_progress_bar: ProgressBar = $UiLayer/PreparationPanel/Margin/VBox/PreparationProgressBar
@onready var _background: TextureRect = $UiLayer/Background
@onready var _mechanic_portrait: TextureRect = $UiLayer/MechanicPortrait
@onready var _intro_overlay: Control = $UiLayer/IntroOverlay
@onready var _intro_narrative_label: Label = $UiLayer/IntroOverlay/CenterContainer/IntroPanel/Margin/VBox/IntroNarrative
@onready var _intro_ok_button: Button = $UiLayer/IntroOverlay/CenterContainer/IntroPanel/Margin/VBox/OkRow/IntroOkButton

var _intro_dismissed := false
var _preparation_complete := false
var _request_in_flight := false
var _portrait_before_request: Texture2D
var _idle_portrait: Texture2D
var _thinking_portrait: Texture2D
var _emotion_portraits: Dictionary[String, Texture2D] = {}
var _speaking_portraits: Array[Texture2D] = []
var _random := RandomNumberGenerator.new()
var _message_input_focus_mode: Control.FocusMode
var _send_button_focus_mode: Control.FocusMode

var _can_interact: bool:
	get:
		return _intro_dismissed and _preparation_complete and not _request_in_flight


func _ready() -> void:
	_intro_overlay.visible = true
	_background.texture = _load_texture("res://Art/Background/background.png")
	_idle_portrait = _load_texture(IDLE_PORTRAIT)
	_thinking_portrait = _load_texture(THINKING_PORTRAIT)
	_emotion_portraits = {
		"angry": _load_texture(ANGRY_PORTRAIT),
		"happy": _load_texture(HAPPY_PORTRAIT),
		"sad": _load_texture(SAD_PORTRAIT),
		"thinking": _thinking_portrait,
	}
	for path in SPEAKING_PORTRAITS:
		_speaking_portraits.append(_load_texture(path))
	_mechanic_portrait.texture = _idle_portrait
	_response_text.text = ""
	_random.randomize()

	_message_input_focus_mode = _message_input.focus_mode
	_send_button_focus_mode = _send_button.focus_mode
	_message_input.focus_mode = Control.FOCUS_NONE
	_send_button.focus_mode = Control.FOCUS_NONE

	var active_profile := _chat_responder.get_active_profile()
	if active_profile == null:
		push_error("Для вступления не назначен профиль персонажа.")
		return
	_intro_narrative_label.text = active_profile.player_introduction

	_send_button.pressed.connect(_on_send_button_pressed)
	_intro_ok_button.pressed.connect(_on_intro_ok_pressed)
	_message_input.gui_input.connect(_on_message_input_gui_input)
	_chat_responder.response_started.connect(_on_response_started)
	_chat_responder.response_emotion_received.connect(_on_response_emotion_received)
	_chat_responder.preparation_started.connect(_on_preparation_started)
	_chat_responder.preparation_progress.connect(_on_preparation_progress)
	_chat_responder.preparation_finished.connect(_on_preparation_finished)
	_chat_responder.response_received.connect(_on_response_received)
	_chat_responder.response_failed.connect(_on_response_failed)
	_status_label.text = "Готов к диалогу."
	_update_interaction_enabled()
	_chat_responder.prepare()


func _on_send_button_pressed() -> void:
	_submit_message()


func _on_intro_ok_pressed() -> void:
	_intro_dismissed = true
	_intro_overlay.visible = false
	_message_input.focus_mode = _message_input_focus_mode
	_send_button.focus_mode = _send_button_focus_mode
	_update_interaction_enabled()
	if _can_interact:
		_message_input.grab_focus()


func _on_message_input_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	# Shift+Enter оставляет перевод строки в TextEdit, обычный Enter отправляет сообщение.
	if event.keycode != KEY_ENTER or event.shift_pressed:
		return
	get_viewport().set_input_as_handled()
	_submit_message()


func _submit_message() -> void:
	if not _can_interact or _chat_responder.is_busy:
		return
	var message := _message_input.text.strip_edges()
	if message.is_empty():
		_status_label.text = "Введите сообщение."
		return

	_request_in_flight = true
	_update_interaction_enabled()
	_status_label.text = "Механик думает…"
	_chat_responder.request_response(message)


func _on_response_started() -> void:
	_portrait_before_request = _mechanic_portrait.texture
	_mechanic_portrait.texture = _thinking_portrait
	_status_label.text = "Механик думает…"
	_update_interaction_enabled()


func _on_preparation_started() -> void:
	_preparation_complete = false
	_preparation_panel.visible = true
	_preparation_status_label.text = "Подключение к локальной модели…"
	_preparation_progress_bar.indeterminate = true
	_status_label.text = "Подготовка персонажа…"
	_update_interaction_enabled()


func _on_preparation_progress(stage: String, fraction: float) -> void:
	var stage_text := "Подготовка локальной модели…"
	match stage:
		"StartingRuntime":
			stage_text = "Запуск сервиса локальной модели…"
		"CheckingModel":
			stage_text = "Проверка установленной модели…"
		"LoadingModel":
			stage_text = "Загрузка модели в память…"

	if is_finite(fraction) and fraction >= 0.0:
		var bounded_fraction := clampf(fraction, 0.0, 1.0)
		_preparation_status_label.text = "%s %d%%" % [stage_text, roundi(bounded_fraction * 100.0)]
		_preparation_progress_bar.indeterminate = false
		_preparation_progress_bar.value = bounded_fraction * 100.0
		return

	_preparation_status_label.text = stage_text
	_preparation_progress_bar.indeterminate = true


func _on_preparation_finished() -> void:
	_preparation_complete = true
	_preparation_panel.visible = false
	_status_label.text = "Готов к диалогу."
	_update_interaction_enabled()
	if _can_interact:
		_message_input.grab_focus()


func _on_response_emotion_received(emotion: String) -> void:
	_mechanic_portrait.texture = _portrait_for_emotion(emotion)


func _on_response_received(response: String) -> void:
	_response_text.text = response
	_message_input.text = ""
	_status_label.text = "Готово."
	_portrait_before_request = null
	_finish_request()


func _on_response_failed(error: String) -> void:
	_mechanic_portrait.texture = _portrait_before_request if _portrait_before_request != null else _idle_portrait
	_portrait_before_request = null
	if not _preparation_complete:
		var preparation_error := "Не удалось подготовить локальную модель: %s" % error
		_preparation_panel.visible = true
		_preparation_status_label.text = preparation_error
		_preparation_progress_bar.indeterminate = false
		_preparation_progress_bar.value = 0.0
		_status_label.text = preparation_error
	else:
		_status_label.text = "Не удалось получить ответ: %s" % error
	_finish_request()


func _portrait_for_emotion(emotion: String) -> Texture2D:
	var normalized := emotion.strip_edges().to_lower()
	if _emotion_portraits.has(normalized):
		return _emotion_portraits[normalized]
	return _speaking_portraits[_random.randi_range(0, _speaking_portraits.size() - 1)]


func _load_texture(path: String) -> Texture2D:
	var texture := load(path) as Texture2D
	if texture == null:
		push_error("Не удалось загрузить изображение персонажа: %s" % path)
	return texture


func _finish_request() -> void:
	_request_in_flight = false
	_update_interaction_enabled()
	if _can_interact:
		_message_input.grab_focus()


func _update_interaction_enabled() -> void:
	var enabled := _can_interact
	_message_input.editable = enabled
	_send_button.disabled = not enabled
	if not enabled:
		_message_input.release_focus()
