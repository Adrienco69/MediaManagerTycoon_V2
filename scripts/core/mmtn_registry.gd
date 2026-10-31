class_name MMTNRegistry
extends RefCounted

const INITIAL_LAUNCH_DATE: String = "Lundi 1 Floréal 0001"


static func get_initial_channels(player_channel: Dictionary, player_company: String) -> Array[Dictionary]:
	var channels: Array[Dictionary] = []
	if player_channel.is_empty():
		return channels

	channels.append({
		"mmtn_number": 1,
		"name": "MG1",
		"group": "Media Groupe",
		"theme": "Généraliste",
		"launch_date": INITIAL_LAUNCH_DATE,
		"closed_date": "",
		"is_open": true
	})

	var player_entry: Dictionary = player_channel.duplicate(true)
	player_entry["group"] = player_company
	player_entry["closed_date"] = String(player_entry.get("closed_date", ""))
	player_entry["is_open"] = bool(player_entry.get("is_open", true))
	channels.append(player_entry)
	return channels


static func get_status_text(channel: Dictionary) -> String:
	var closed_date: String = String(channel.get("closed_date", ""))
	if not closed_date.is_empty():
		return "Fermée le %s" % closed_date
	return "Ouverte"
