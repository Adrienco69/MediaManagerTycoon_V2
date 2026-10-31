extends Node

signal time_changed
signal credits_changed(new_value: int)
signal speed_changed(new_mode: int)

enum TimeMode {
	PAUSED,
	HOUR,
	DAY,
	WEEK
}

const DAYS := [
	"Lundi",
	"Mardi",
	"Mercredi",
	"Jeudi",
	"Vendredi",
	"Samedi",
	"Dimanche"
]

const MONTHS := [
	{"name": "Floréal", "weeks": 7},
	{"name": "Clôture", "weeks": 8},
	{"name": "Crépuscule", "weeks": 7},
	{"name": "Zénith", "weeks": 8},
	{"name": "Origine", "weeks": 7},
	{"name": "Essor", "weeks": 8},
	{"name": "Brumal", "weeks": 7}
]

const STARTING_CREDITS := 1200

# Vitesses validées :
# - Heure : 10 secondes réelles = 1 heure de jeu.
# - Jour : 20 secondes réelles = 1 journée de jeu.
# - Semaine : 30 secondes réelles = 1 semaine de jeu.
const GAME_MINUTES_PER_REAL_SECOND := {
	TimeMode.HOUR: 6.0,
	TimeMode.DAY: 72.0,
	TimeMode.WEEK: 336.0
}

var credits: int = STARTING_CREDITS
var year: int = 1
var month_index: int = 0
var week_in_month: int = 1
var week_in_year: int = 1
var day_in_week: int = 1
var hour: int = 0
var minute: int = 0
var time_mode: TimeMode = TimeMode.PAUSED

var _minute_buffer: float = 0.0


func _process(delta: float) -> void:
	if time_mode == TimeMode.PAUSED:
		return

	_minute_buffer += delta * GAME_MINUTES_PER_REAL_SECOND[time_mode]
	var whole_minutes := int(floor(_minute_buffer))
	if whole_minutes <= 0:
		return

	_minute_buffer -= whole_minutes
	advance_minutes(whole_minutes)


func set_time_mode(new_mode: TimeMode) -> void:
	if time_mode == new_mode:
		return
	time_mode = new_mode
	speed_changed.emit(time_mode)


func set_credits(new_value: int) -> void:
	credits = max(new_value, 0)
	credits_changed.emit(credits)


func add_credits(amount: int) -> void:
	set_credits(credits + amount)


func spend_credits(amount: int) -> bool:
	if amount < 0 or credits < amount:
		return false
	set_credits(credits - amount)
	return true


func advance_minutes(amount: int) -> void:
	if amount <= 0:
		return

	var total_minutes := minute + amount
	minute = total_minutes % 60

	var total_hours := hour + int(total_minutes / 60)
	hour = total_hours % 24

	var days_to_advance := int(total_hours / 24)
	for _i in range(days_to_advance):
		_advance_one_day()

	time_changed.emit()


func _advance_one_day() -> void:
	day_in_week += 1
	if day_in_week <= 7:
		return

	day_in_week = 1
	week_in_month += 1
	week_in_year += 1

	var current_month_weeks: int = int(MONTHS[month_index]["weeks"])
	if week_in_month <= current_month_weeks:
		return

	week_in_month = 1
	month_index += 1

	if month_index < MONTHS.size():
		return

	month_index = 0
	year += 1
	week_in_year = 1


func get_day_name() -> String:
	return DAYS[day_in_week - 1]


func get_month_name() -> String:
	return String(MONTHS[month_index]["name"])


func get_day_of_month() -> int:
	return ((week_in_month - 1) * 7) + day_in_week


func get_date_text() -> String:
	return "%s %d %s %04d" % [get_day_name(), get_day_of_month(), get_month_name(), year]


func get_week_text() -> String:
	return "Semaine %d/52" % week_in_year


func get_time_text() -> String:
	return "%02d:%02d" % [hour, minute]


func get_speed_text() -> String:
	match time_mode:
		TimeMode.HOUR:
			return "Heure"
		TimeMode.DAY:
			return "Jour"
		TimeMode.WEEK:
			return "Semaine"
		_:
			return "Pause"
