class_name NpcPersona
extends RefCounted

var npc_name: String
var role: String
var character: String
var speech_style: String
var player_attitude: String
var knowledge: String
var behavior_constraints: String


func _init(
		p_npc_name: String,
		p_role: String,
		p_character: String,
		p_speech_style: String,
		p_player_attitude: String,
		p_knowledge: String,
		p_behavior_constraints: String
	) -> void:
	npc_name = p_npc_name.strip_edges()
	role = p_role.strip_edges()
	character = p_character.strip_edges()
	speech_style = p_speech_style.strip_edges()
	player_attitude = p_player_attitude.strip_edges()
	knowledge = p_knowledge.strip_edges()
	behavior_constraints = p_behavior_constraints.strip_edges()


func is_valid() -> bool:
	return not npc_name.is_empty() and not role.is_empty() and not character.is_empty() \
		and not speech_style.is_empty() and not player_attitude.is_empty() \
		and not knowledge.is_empty() and not behavior_constraints.is_empty()


func to_context_text() -> String:
	return "Имя: %s\n" % npc_name \
		+ "Роль: %s\n" % role \
		+ "Характер: %s\n" % character \
		+ "Стиль речи: %s\n" % speech_style \
		+ "Отношение к игроку: %s\n" % player_attitude \
		+ "Что знает и чего не знает: %s\n" % knowledge \
		+ "Ограничения поведения: %s" % behavior_constraints
