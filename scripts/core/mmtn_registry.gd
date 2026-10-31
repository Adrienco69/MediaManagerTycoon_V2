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
		"launch_date": INITIAL_LAUNCH_DATE
	})

	var player_entry: Dictionary = player_channel.duplicate(true)
	player_entry["group"] = player_company
	channels.append(player_entry)
	return channels
