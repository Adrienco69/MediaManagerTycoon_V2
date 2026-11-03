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
	var launch_programs: Array[Dictionary] = LaunchProgramCatalogScript.build(channel_name, player_series_telefilm)
	for program: Dictionary in launch_programs:
		_programs.append(_normalize_program(program))


func load_data(
	programs: Array,
	distribution: Dictionary,
	active_productions: Array = []
) -> void:
	_programs.clear()
	_active_productions.clear()

	for value: Variant in programs:
		if value is Dictionary:
			_programs.append(_normalize_program(value as Dictionary))

	var occupied_slots: Dictionary = {}
	for value: Variant in active_productions:
		if not value is Dictionary:
			continue
		var production: Dictionary = _normalize_program(value as Dictionary)
		var slot_index: int = int(production.get("slot_index", 0))
		if slot_index < 1 or slot_index > MAX_ACTIVE_PRODUCTIONS or occupied_slots.has(slot_index):
			slot_index = _first_free_slot_from(occupied_slots)
		production["slot_index"] = slot_index
		occupied_slots[slot_index] = true
		_active_productions.append(production)

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
		return "Les 7 slots du Studio 1 sont déjà occupés."

	var name: String = String(spec.get("name", "")).strip_edges()
	var format_name: String = String(spec.get("format", ""))
	var duration_minutes: int = int(spec.get("duration_minutes", 0))
	var unit_count: int = maxi(int(spec.get("units_total", spec.get("episodes_total", 0))), 1)

	if name.is_empty():
		return "Le nom du programme est obligatoire."
	if _name_exists(name):
		return "Un programme portant ce nom existe déjà dans votre groupe."
	if not ProductionRulesScript.get_formats().has(format_name):
		return "Ce format n'est pas encore disponible dans le système de production."
	if not ProductionRulesScript.get_durations(format_name).has(duration_minutes):
		return "Cette durée n'est pas autorisée pour ce format."

	if ProductionRulesScript.is_single_unit(format_name):
		unit_count = 1

	var total_minutes: int = ProductionRulesScript.get_total_minutes(
		format_name,
		duration_minutes,
		unit_count
	)
	if total_minutes <= 0:
		return "La durée de production de ce format n'est pas encore définie."

	var slot_index: int = _get_free_slot_index()
	if slot_index <= 0:
		return "Les 7 slots du Studio 1 sont déjà occupés."

	var production: Dictionary = {
		"id": _make_id(name),
		"name": name,
		"format": format_name,
		"duration_minutes": duration_minutes,
		"units_total": unit_count,
		"units_available": 0,
		# Clés conservées pour compatibilité avec les écrans/sauvegardes existants.
		"episodes_total": unit_count,
		"episodes_available": 0,
		"units": _build_units(unit_count),
		"status": "Production en cours",
		"season_count": 0,
		"seasons": [],
		"broadcast_history": [],
		"source": "production",
		"owned_by_group": true,
		"production_mode": "lot",
		"slot_index": slot_index,
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
		var after_remaining: int = maxi(before_remaining - amount, 0)
		production["production_remaining_minutes"] = after_remaining
		_active_productions[index] = production

		if before_remaining != after_remaining:
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


func get_program_units(program_id: String) -> Array[Dictionary]:
	var program: Dictionary = get_program(program_id)
	var result: Array[Dictionary] = []
	var units_value: Variant = program.get("units", [])
	if units_value is Array:
		for value: Variant in units_value:
			if value is Dictionary:
				result.append((value as Dictionary).duplicate(true))
	return result


func set_editorial_season(program_id: String, season_number: int, code_prod_order: Array[int]) -> String:
	if season_number <= 0:
		return "Le numéro de saison doit être supérieur à 0."
	if code_prod_order.is_empty():
		return "La saison doit contenir au moins une unité."

	for index: int in range(_programs.size()):
		var program: Dictionary = _programs[index]
		if String(program.get("id", "")) != program_id:
			continue

		var total_units: int = ProductionRulesScript.get_unit_count(program)
		var seen: Dictionary = {}
		for code_prod: int in code_prod_order:
			if code_prod < 1 or code_prod > total_units:
				return "Le code prod %d n'existe pas pour ce programme." % code_prod
			if seen.has(code_prod):
				return "Le code prod %d est présent plusieurs fois dans la saison." % code_prod
			seen[code_prod] = true

		var units: Array[Dictionary] = _get_units(program)
		for unit_index: int in range(units.size()):
			var unit: Dictionary = units[unit_index]
			if int(unit.get("season", 0)) == season_number or seen.has(int(unit.get("code_prod", 0))):
				unit["season"] = 0
				unit["episode_in_season"] = 0
				units[unit_index] = unit

		for editorial_index: int in range(code_prod_order.size()):
			var code_prod: int = code_prod_order[editorial_index]
			var unit_array_index: int = code_prod - 1
			var unit: Dictionary = units[unit_array_index]
			unit["season"] = season_number
			unit["episode_in_season"] = editorial_index + 1
			units[unit_array_index] = unit

		var seasons: Array[Dictionary] = _get_seasons(program)
		var replaced: bool = false
		for season_index: int in range(seasons.size()):
			if int(seasons[season_index].get("number", 0)) == season_number:
				seasons[season_index] = {"number": season_number, "unit_codes": code_prod_order.duplicate()}
				replaced = true
				break
		if not replaced:
			seasons.append({"number": season_number, "unit_codes": code_prod_order.duplicate()})
		seasons.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("number", 0)) < int(b.get("number", 0))
		)

		program["units"] = units
		program["seasons"] = seasons
		program["season_count"] = seasons.size()
		_programs[index] = program
		return ""

	return "Programme introuvable."


func record_broadcast(
	program_id: String,
	season_number: int,
	episode_number: int,
	date_text: String,
	time_text: String,
	channel_name: String,
	broadcast_type: String,
	audience_viewers: int = 0,
	revenue_cc: int = 0
) -> bool:
	for index: int in range(_programs.size()):
		var program: Dictionary = _programs[index]
		if String(program.get("id", "")) != program_id:
			continue

		var code_prod: int = _resolve_code_prod(program, season_number, episode_number)
		var history_value: Variant = program.get("broadcast_history", [])
		var history: Array = []
		if history_value is Array:
			history = history_value

		history.append({
			"code_prod": code_prod,
			"episode_global": code_prod,
			"season": maxi(season_number, 0),
			"episode": maxi(episode_number, 0),
			"date": date_text,
			"time": time_text,
			"channel": channel_name,
			"type": broadcast_type,
			"audience_viewers": audience_viewers,
			"revenue_cc": revenue_cc
		})
		program["broadcast_history"] = history
		_programs[index] = program
		return true

	return false


func _finalize_production(production: Dictionary) -> void:
	var completed: Dictionary = _normalize_program(production)
	var total_units: int = ProductionRulesScript.get_unit_count(completed)

	completed["units_available"] = total_units
	completed["episodes_available"] = total_units
	completed["status"] = "Disponible"
	completed["season_count"] = 0
	completed["seasons"] = []

	var units: Array[Dictionary] = _get_units(completed)
	for unit_index: int in range(units.size()):
		var unit: Dictionary = units[unit_index]
		unit["season"] = 0
		unit["episode_in_season"] = 0
		units[unit_index] = unit
	completed["units"] = units

	completed.erase("production_total_minutes")
	completed.erase("production_remaining_minutes")
	completed.erase("production_cost")
	completed.erase("slot_index")
	_programs.append(completed)


func _normalize_program(source: Dictionary) -> Dictionary:
	var program: Dictionary = source.duplicate(true)
	var total_units: int = ProductionRulesScript.get_unit_count(program)
	program["units_total"] = total_units
	program["episodes_total"] = total_units

	if not program.has("units_available"):
		program["units_available"] = int(program.get("episodes_available", total_units))
	if not program.has("episodes_available"):
		program["episodes_available"] = int(program.get("units_available", total_units))

	var units: Array[Dictionary] = _get_units(program)
	if units.size() != total_units:
		units = _build_units(total_units)
	program["units"] = units
	_apply_legacy_seasons(program)
	return program


func _apply_legacy_seasons(program: Dictionary) -> void:
	var seasons: Array[Dictionary] = _get_seasons(program)
	if seasons.is_empty():
		return

	var units: Array[Dictionary] = _get_units(program)
	for season: Dictionary in seasons:
		var season_number: int = int(season.get("number", 0))
		if season_number <= 0:
			continue

		var codes: Array[int] = []
		var codes_value: Variant = season.get("unit_codes", [])
		if codes_value is Array:
			for code_value: Variant in codes_value:
				var code: int = int(code_value)
				if code > 0:
					codes.append(code)

		if codes.is_empty():
			var first_episode: int = int(season.get("first_episode", 0))
			var last_episode: int = int(season.get("last_episode", 0))
			if first_episode > 0 and last_episode >= first_episode:
				for code_prod: int in range(first_episode, last_episode + 1):
					codes.append(code_prod)

		for editorial_index: int in range(codes.size()):
			var code_prod: int = codes[editorial_index]
			if code_prod < 1 or code_prod > units.size():
				continue
			var unit: Dictionary = units[code_prod - 1]
			unit["season"] = season_number
			unit["episode_in_season"] = editorial_index + 1
			units[code_prod - 1] = unit

	program["units"] = units
	program["season_count"] = seasons.size()


func _build_units(total_units: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for code_prod: int in range(1, maxi(total_units, 1) + 1):
		result.append({
			"code_prod": code_prod,
			"season": 0,
			"episode_in_season": 0,
			"title": ""
		})
	return result


func _get_units(program: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var units_value: Variant = program.get("units", [])
	if units_value is Array:
		for value: Variant in units_value:
			if value is Dictionary:
				result.append((value as Dictionary).duplicate(true))
	return result


func _get_seasons(program: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seasons_value: Variant = program.get("seasons", [])
	if seasons_value is Array:
		for value: Variant in seasons_value:
			if value is Dictionary:
				result.append((value as Dictionary).duplicate(true))
	return result


func _resolve_code_prod(program: Dictionary, season_number: int, episode_number: int) -> int:
	if season_number <= 0:
		return maxi(episode_number, 0)

	for unit: Dictionary in _get_units(program):
		if int(unit.get("season", 0)) == season_number and int(unit.get("episode_in_season", 0)) == episode_number:
			return int(unit.get("code_prod", 0))
	return 0


func _get_free_slot_index() -> int:
	var occupied: Dictionary = {}
	for production: Dictionary in _active_productions:
		var slot_index: int = int(production.get("slot_index", 0))
		if slot_index > 0:
			occupied[slot_index] = true
	return _first_free_slot_from(occupied)


func _first_free_slot_from(occupied: Dictionary) -> int:
	for slot_index: int in range(1, MAX_ACTIVE_PRODUCTIONS + 1):
		if not occupied.has(slot_index):
			return slot_index
	return 0


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
