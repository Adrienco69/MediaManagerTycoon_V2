class_name ProductionRules
extends RefCounted

const HOUR_MINUTES: int = 60
const DAY_MINUTES: int = 1440
const FORMATS: Array[String] = [
	"Série",
	"Shortcom",
	"Série-téléfilm",
	"Téléfilm",
	"Film"
]


static func get_formats() -> Array[String]:
	var result: Array[String] = []
	for format_name: String in FORMATS:
		result.append(format_name)
	return result


static func get_durations(format_name: String) -> Array[int]:
	var result: Array[int] = []
	match format_name:
		"Série":
			result = [30, 60, 90]
		"Shortcom":
			result = [30]
		"Série-téléfilm":
			result = [60, 90]
		"Téléfilm":
			result = [90, 120]
		"Film":
			result = [90, 120, 150, 180]
	return result


static func is_single_unit(format_name: String) -> bool:
	return format_name == "Téléfilm" or format_name == "Film"


static func get_cost(format_name: String) -> int:
	if format_name == "Téléfilm" or format_name == "Film":
		return 1700
	return 850


static func get_unit_work_minutes(format_name: String) -> int:
	match format_name:
		"Shortcom":
			return 1 * HOUR_MINUTES
		"Série":
			return 2 * HOUR_MINUTES
		"Série-téléfilm":
			return 10 * HOUR_MINUTES
		"Téléfilm":
			return 23 * HOUR_MINUTES
		"Film":
			return 24 * HOUR_MINUTES
	return 0


static func get_total_minutes(
	format_name: String,
	_duration_minutes: int,
	unit_count: int
) -> int:
	var units: int = 1 if is_single_unit(format_name) else maxi(unit_count, 1)
	var work_per_unit: int = get_unit_work_minutes(format_name)
	if work_per_unit <= 0:
		return 0
	return work_per_unit * units


static func get_total_days(
	format_name: String,
	duration_minutes: int,
	unit_count: int
) -> int:
	var total_minutes: int = get_total_minutes(format_name, duration_minutes, unit_count)
	if total_minutes <= 0:
		return 0
	return int(ceil(float(total_minutes) / float(DAY_MINUTES)))


static func get_completed_unit_count(production: Dictionary) -> int:
	var total_units: int = get_unit_count(production)
	var remaining_minutes: int = maxi(int(production.get("production_remaining_minutes", 0)), 0)
	return total_units if remaining_minutes <= 0 else 0


static func get_produced_episode_count(production: Dictionary) -> int:
	# Compatibilité avec les anciens écrans/sauvegardes : un lot n'est disponible
	# qu'une fois entièrement terminé, donc aucune unité n'est considérée comme
	# produite/diffusable avant la fin du lot.
	return get_completed_unit_count(production)


static func get_unit_count(program: Dictionary) -> int:
	var units_total: int = int(program.get("units_total", 0))
	if units_total > 0:
		return units_total
	return maxi(int(program.get("episodes_total", 1)), 1)


static func format_remaining_time(remaining_minutes: int) -> String:
	var safe_minutes: int = maxi(remaining_minutes, 0)
	var days: int = int(safe_minutes / DAY_MINUTES)
	var rest: int = safe_minutes % DAY_MINUTES
	var hours: int = int(rest / 60)
	var minutes: int = rest % 60

	if days > 0 and hours == 0 and minutes == 0:
		return "%d j" % days
	if days > 0:
		return "%d j %02dh%02d" % [days, hours, minutes]
	return "%02dh%02d" % [hours, minutes]
