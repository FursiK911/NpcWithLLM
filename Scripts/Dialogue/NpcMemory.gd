class_name NpcMemory
extends RefCounted

var _player_name_pattern := RegEx.new()
var _player_profession_pattern := RegEx.new()
var _player_profession_identity_pattern := RegEx.new()
var _facts: Dictionary[String, String] = {}

var player_name: String:
	get:
		return _facts.get("имя игрока", "")

var player_profession: String:
	get:
		return _facts.get("профессия игрока", "")


func _init() -> void:
	_player_name_pattern.compile("(?:меня зовут|мо[её] имя)\\s+([а-яёa-z][а-яёa-z-]{1,30})")
	_player_profession_pattern.compile("(?:(?<![а-яёa-z0-9_])я(?![а-яёa-z0-9_])\\s+работаю\\s+(?:как\\s+)?|моя профессия\\s*[—–:-]?\\s*)([а-яёa-z][а-яёa-z-]{2,})")
	_player_profession_identity_pattern.compile("(?<![а-яёa-z0-9_])я\\s+(?:тоже\\s+)?(?:[—–:]\\s*)?(механик|программистка?|врач|инженер|учительница?|преподавательница?|водитель|повар|электрик|строитель|слесарь|токарь|бухгалтер|юрист|дизайнер|художник|журналист|студентка?|архитектор)(?![а-яёa-z0-9_])")


func learn_from(player_message: String) -> void:
	if player_message.strip_edges().is_empty():
		return

	var normalized := player_message.strip_edges()
	var comparable := normalized.to_lower()
	var name_match := _player_name_pattern.search(comparable)
	if name_match:
		_remember("имя игрока", normalized.substr(name_match.get_start(1), name_match.get_end(1) - name_match.get_start(1)))

	var profession_match := _player_profession_pattern.search(comparable)
	if not profession_match:
		profession_match = _player_profession_identity_pattern.search(comparable)
	if profession_match:
		var profession := normalized.substr(profession_match.get_start(1), profession_match.get_end(1) - profession_match.get_start(1))
		if not _is_non_profession_word(profession):
			_remember("профессия игрока", profession)


func to_context_text() -> String:
	if _facts.is_empty():
		return "Пока нет сохранённых фактов о игроке."

	var facts: Array[String] = []
	for key in _facts:
		facts.append("%s: %s" % [key, _facts[key]])
	return "\n".join(facts)


func _remember(key: String, value: String) -> void:
	var normalized := value.strip_edges()
	while not normalized.is_empty() and normalized.right(1) in [".", "!", "?", ","]:
		normalized = normalized.left(normalized.length() - 1)
	_facts[key] = normalized


func _is_non_profession_word(value: String) -> bool:
	return value.to_lower() in ["устал", "занят", "дома", "готов"]
