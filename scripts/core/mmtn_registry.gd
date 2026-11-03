class_name MMTNRegistry
extends RefCounted

const MG1LaunchCatalogScript = preload("res://scripts/core/mg1_launch_catalog.gd")

const INITIAL_LAUNCH_DATE: String = "Lundi 1 Floréal 0001"

var _history: Array[Dictionary] = []


func reset() -> void:
	_history.clear()


func register_initial_channels(
	player_channel: Dictionary,
	player_company: String,
	player_programs: Array[Dictionary],
	mg1_series_telefilm: Dictionary
) -> void:
	if player_channel.is_empty() or not _history.is_empty():
		return

	var mg1_programs: Array[Dictionary] = MG1LaunchCatalogScript.build(
		player_programs,
		mg1_series_telefilm
	)

	_history.append({
		"mmtn_number": 1,
		"arrival_order": 1,
		"name": "MG1",
		"group": "Media Groupe",
		"theme": "Généraliste",
		"launch_date": INITIAL_LAUNCH_DATE,
		"closed_date": "",
		"is_open": true,
		"programs": mg1_programs,
		"auto_schedule": true,
		"schedule_seed": randi_range(100000, 999999999)
	})

	var player_entry: Dictionary = player_channel.duplicate(true)
	player_entry["arrival_order"] = _history.size() + 1
	player_entry["group"] = player_company
	player_entry["launch_date"] = String(player_entry.get("launch_date", INITIAL_LAUNCH_DATE))
	player_entry["closed_date"] = String(player_entry.get("closed_date", ""))
	player_entry["is_open"] = bool(player_entry.get("is_open", true))
	_history.append(player_entry)


func register_channel(channel: Dictionary) -> void:
	if channel.is_empty():
		return

	var entry: Dictionary = channel.duplicate(true)
	# Une nouvelle chaîne se place après toutes celles déjà arrivées.
	entry["arrival_order"] = _history.size() + 1
	entry["closed_date"] = String(entry.get("closed_date", ""))
	entry["is_open"] = bool(entry.get("is_open", true))
	_history.append(entry)


func load_history(history: Array) -> void:
	_history.clear()
	for value: Variant in history:
		if value is Dictionary:
			var restored: Dictionary = (value as Dictionary).duplicate(true)
			# Compatibilité des sauvegardes antérieures : l’ordre des entrées
			# enregistrées constitue leur ordre d’arrivée historique.
			if not restored.has("arrival_order"):
				restored["arrival_order"] = _history.size() + 1
			_history.append(restored)


func close_channel(mmtn_number: int, closed_date: String) -> bool:
	for index: int in range(_history.size()):
		if int(_history[index].get("mmtn_number", 0)) != mmtn_number:
			continue
		_history[index]["is_open"] = false
		_history[index]["closed_date"] = closed_date
		return true
	return false


func get_channels() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for channel: Dictionary in _history:
		result.append(channel.duplicate(true))
	return result


static func get_status_text(channel: Dictionary) -> String:
	var closed_date: String = String(channel.get("closed_date", ""))
	if not closed_date.is_empty():
		return "Fermée le %s" % closed_date
	return "Ouverte"
