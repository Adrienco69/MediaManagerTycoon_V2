class_name PlayerIdentity
extends RefCounted

var player_name: String = ""
var company_name: String = ""


func reset() -> void:
	player_name = ""
	company_name = ""


func set_identity(new_player_name: String, new_company_name: String) -> void:
	player_name = new_player_name.strip_edges()
	company_name = new_company_name.strip_edges()


func is_valid() -> bool:
	return not player_name.is_empty() and not company_name.is_empty()
