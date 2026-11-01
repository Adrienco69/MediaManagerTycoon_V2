class_name ProductionManager
extends RefCounted

const LaunchProgramCatalogScript = preload("res://scripts/core/launch_program_catalog.gd")
const LaunchSeriesTelefilmDistributionScript = preload("res://scripts/core/launch_series_telefilm_distribution.gd")
const ProductionRulesScript = preload("res://scripts/core/production_rules.gd")

const MAX_ACTIVE_PRODUCTIONS: int = 7

var _programs: Array[Dictionary] = []
var _active_productions: Array[Dictionary] = []
var _launch_series_telefilm_distribution: Dictionary = {}


func reset() -> void:
	_programs.clear()
	_active_productions.clear()
	_launch_series_telefilm_distribution.clear()


func assign_launch_programs(channel_name: String) -> void:
	if not _programs.is_empty():
		return

	_launch_series_telefilm_distribution = LaunchSeriesTelefilmDistributionScript.draw()
	var player_series_telefilm: Dictionary = _launch_series_telefilm_distribution.get("player", {})
	_programs = LaunchProgramCatalogScript.build(channel_name, player_series_telefilm)


func load_data(
	programs: Array,
	distribution: Dictionary,
	active_productions: Array = []
) -> void:
	_programs.clear()
	_active_productions.clear()

	for value: Variant in programs:
		if value is Dictionary:
			_programs.append((value as Dictionary).duplicate(true))

	for value: Variant in active_productions:
		if value is Dictionary:
			_active_productions.append((value as Dictionary).duplicate(true))

	_launch_series_telefilm_distribution = distribution.duplicate(true)


func get_programs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for program: Dictionary in _programs:
		result.append(program.duplicate(true))
	return result


func get_active_productions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for production: Dictionary in _active_productions:
		result.append(production.duplicate(true))
	return result


func start_new_production(spec: Dictionary) -> String:
	if _active_productions.size() >= MAX_ACTIVE_PRODUCTIONS:
		return "Les 7 sets du Studio 1 sont déjà occupés."

	var name: String = String(spec.get("name", "")).strip_edges()
	var format_name: String = String(spec.get("format", ""))
	var duration_minutes: int = int(spec.get("duration_minutes", 0))
	var episode_count: int = maxi(int(spec.get("episodes_total", 0)), 1)

	if name.is_empty():
		return "Le nom du programme est obligatoire."
	if _name_exists(name):
		return "Un programme portant ce nom existe déjà dans votre groupe."
	if not ProductionRulesScript.get_formats().has(format_name):
		return "Ce format n'est pas encore disponible dans le système de production."
	if not ProductionRulesScript.get_durations(format_name).has(duration_minutes):
		return "Cette durée n'est pas autorisée pour ce format."

	if ProductionRulesScript.is_single_unit(format_name):
		episode_count = 1

	var total_minutes: int = ProductionRulesScript.get_total_minutes(
		format_name,
		duration_minutes,
		episode_count
	)
	if total_minutes <= 0:
		return "La durée de production de ce format n'est pas encore définie."

	var season_number: int = 0 if ProductionRulesScript.is_single_unit(format_name) else 1
	var production: Dictionary = {
		"id": _make_id(name),
		"name": name,
		"format": format_name,
		"duration_minutes": duration_minutes,
		"episodes_total": episode_count,
		"episodes_available": 0,
		"status": "Production en cours",
		"current_episode": 0,
		"season_count": season_number,
		"season_number": season_number,
		"seasons": [],
		"broadcast_history": [],
		"source": "production",
		"owned_by_group": true,
		"production_total_minutes": total_minutes,
		"production_remaining_minutes": total_minutes,
		"production_cost": ProductionRulesScript.get_cost(format_name)
	}

	_active_productions.append(production)
	return ""


func advance_minutes(amount: int) -> bool:
	if amount <= 0 or _active_productions.is_empty():
		return false

	var visible_change: bool = false
	for index: int in range(_active_productions.size() - 1, -1, -1):
		var production: Dictionary = _active_productions[index]
		var before_remaining: int = maxi(int(production.get("production_remaining_minutes", 0)), 0)
		var before_produced: int = ProductionRulesScript.get_produced_episode_count(production)
		var before_days: int = int(ceil(float(before_remaining) / float(ProductionRulesScript.DAY_MINUTES)))

		var after_remaining: int = maxi(before_remaining - amount, 0)
		production["production_remaining_minutes"] = after_remaining
		_active_productions[index] = production

		var after_produced: int = ProductionRulesScript.get_produced_episode_count(production)
		var after_days: int = int(ceil(float(after_remaining) / float(ProductionRulesScript.DAY_MINUTES)))
		if before_produced != after_produced or before_days != after_days:
			visible_change = true

		if after_remaining <= 0:
			_finalize_production(production)
			_active_productions.remove_at(index)
			visible_change = true

	return visible_change


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


func _finalize_production(production: Dictionary) -> void:
	var completed: Dictionary = production.duplicate(true)
	var total_episodes: int = maxi(int(completed.get("episodes_total", 1)), 1)
	var season_number: int = int(completed.get("season_number", 0))

	completed["episodes_available"] = total_episodes
	completed["status"] = "Disponible"
	completed["current_episode"] = 0

	if season_number > 0:
		completed["season_count"] = season_number
		completed["seasons"] = [{
			"number": season_number,
			"first_episode": 1,
			"last_episode": total_episodes
		}]
	else:
		completed["season_count"] = 0
		completed["seasons"] = []

	completed.erase("production_total_minutes")
	completed.erase("production_remaining_minutes")
	completed.erase("production_cost")
	completed.erase("season_number")
	_programs.append(completed)


func _name_exists(name: String) -> bool:
	var normalized_name: String = name.to_lower()
	for program: Dictionary in _programs:
		if String(program.get("name", "")).to_lower() == normalized_name:
			return true
	for production: Dictionary in _active_productions:
		if String(production.get("name", "")).to_lower() == normalized_name:
			return true
	return false


func _make_id(name: String) -> String:
	return name.to_lower().replace(" ", "_").replace("’", "").replace("'", "")
