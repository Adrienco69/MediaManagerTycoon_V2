class_name ProductionManager
extends RefCounted

const LaunchProgramCatalogScript = preload("res://scripts/core/launch_program_catalog.gd")
const LaunchSeriesTelefilmDistributionScript = preload("res://scripts/core/launch_series_telefilm_distribution.gd")

var _programs: Array[Dictionary] = []
var _launch_series_telefilm_distribution: Dictionary = {}


func reset() -> void:
	_programs.clear()
	_launch_series_telefilm_distribution.clear()


func assign_launch_programs(channel_name: String) -> void:
	if not _programs.is_empty():
		return

	_launch_series_telefilm_distribution = LaunchSeriesTelefilmDistributionScript.draw()
	var player_series_telefilm: Dictionary = _launch_series_telefilm_distribution.get("player", {})
	_programs = LaunchProgramCatalogScript.build(channel_name, player_series_telefilm)


func load_data(programs: Array, distribution: Dictionary) -> void:
	_programs.clear()
	for value: Variant in programs:
		if value is Dictionary:
			_programs.append((value as Dictionary).duplicate(true))
	_launch_series_telefilm_distribution = distribution.duplicate(true)


func get_programs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for program: Dictionary in _programs:
		result.append(program.duplicate(true))
	return result


func get_active_productions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for program: Dictionary in _programs:
		if String(program.get("status", "")) == "Production en cours":
			result.append(program.duplicate(true))
	return result


func get_launch_series_telefilm_distribution() -> Dictionary:
	return _launch_series_telefilm_distribution.duplicate(true)


func get_program(program_id: String) -> Dictionary:
	for program: Dictionary in _programs:
		if String(program.get("id", "")) == program_id:
			return program.duplicate(true)
	return {}


func record_broadcast(
	program_id: String,
	season_number: int,
	episode_number: int,
	date_text: String,
	time_text: String,
	channel_name: String,
	broadcast_type: String
) -> bool:
	for index: int in range(_programs.size()):
		var program: Dictionary = _programs[index]
		if String(program.get("id", "")) != program_id:
			continue

		var history_value: Variant = program.get("broadcast_history", [])
		var history: Array = []
		if history_value is Array:
			history = history_value

		history.append({
			"season": maxi(season_number, 0),
			"episode": maxi(episode_number, 0),
			"date": date_text,
			"time": time_text,
			"channel": channel_name,
			"type": broadcast_type
		})
		program["broadcast_history"] = history
		_programs[index] = program
		return true

	return false
