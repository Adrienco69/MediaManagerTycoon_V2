extends Node

const PlayerChannelManagerScript = preload("res://scripts/core/player_channel_manager.gd")
const MMTNRegistryScript = preload("res://scripts/core/mmtn_registry.gd")

signal time_changed
signal credits_changed(new_value: int)
signal speed_changed(new_mode: int)
signal identity_changed(player_name: String, company_name: String)
signal channel_created(channel: Dictionary)

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

const GAME_MINUTES_PER_REAL_SECOND := {
	TimeMode.HOUR: 6.0,
	TimeMode.DAY: 72.0,
	TimeMode.WEEK: 336.0
}

var player_name: String = ""
var company_name: String = ""
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
var _player_channel_manager: PlayerChannelManager = PlayerChannelManagerScript.new()


func _ready() -> void:
	_player_channel_manager.channel_created.connect(_on_channel_created)


func _process(delta: float) -> void:
	if time_mode == TimeMode.PAUSED:
		return

	_minute_buffer += delta * GAME_MINUTES_PER_REAL_SECOND[time_mode]
	var whole_minutes: int = int(floor(_minute_buffer))
	if whole_minutes <= 0:
		return

	_minute_buffer -= whole_minutes
	advance_minutes(whole_minutes)


func start_new_game(new_player_name: String, new_company_name: String) -> void:
	player_name = new_player_name.strip_edges()
	company_name = new_company_name.strip_edges()
	credits = STARTING_CREDITS
	year = 1
	month_index = 0
	week_in_month = 1
	week_in_year = 1
	day_in_week = 1
	hour = 0
	minute = 0
	time_mode = TimeMode.PAUSED
	_minute_buffer = 0.0
	_player_channel_manager.reset()

	identity_changed.emit(player_name, company_name)
	credits_changed.emit(credits)
	time_changed.emit()
	speed_changed.emit(time_mode)


func has_started_game() -> bool:
	return not player_name.is_empty() and not company_name.is_empty()


func create_first_channel(channel_name: String) -> bool:
	return _player_channel_manager.create_first_channel(channel_name)


func has_player_channel() -> bool:
	return _player_channel_manager.has_first_channel()


func get_first_channel() -> Dictionary:
	return _player_channel_manager.get_first_channel()


func get_player_channels() -> Array[Dictionary]:
	return _player_channel_manager.get_channels()


func get_zap_channels() -> Array[Dictionary]:
	return MMTNRegistryScript.get_initial_channels(get_first_channel(), company_name)


func set_time_mode(new_mode: TimeMode) -> void:
	if time_mode == new_mode:
		return
	time_mode = new_mode
	speed_changed.emit(time_mode)


func set_credits(new_value: int) -> void:
	credits = maxi(new_value, 0)
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

	var total_minutes: int = minute + amount
	minute = total_minutes % 60

	var total_hours: int = hour + int(total_minutes / 60)
	hour = total_hours % 24

	var days_to_advance: int = int(total_hours / 24)
	for _i: int in range(days_to_advance):
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


func _on_channel_created(channel: Dictionary) -> void:
	channel_created.emit(channel)


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
