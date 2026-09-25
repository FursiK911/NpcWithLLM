class_name NpcProfile
extends Resource

@export var npc_name: String = ""
@export var role: String = ""
@export_multiline var player_introduction: String = ""
@export var character: String = ""
@export var speech_style: String = ""
@export var player_attitude: String = ""
@export var knowledge: String = ""
@export var behavior_constraints: String = ""
@export_multiline var situation: String = ""


func to_persona() -> NpcPersona:
	return NpcPersona.new(
		npc_name,
		role,
		character,
		speech_style,
		player_attitude,
		knowledge,
		behavior_constraints
	)
