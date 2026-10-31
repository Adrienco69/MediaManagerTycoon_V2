extends Control

@onready var credits_label: Label = %CreditsLabel
@onready var date_label: Label = %DateLabel
@onready var week_label: Label = %WeekLabel
@onready var time_label: Label = %TimeLabel
@onready var speed_label: Label = %SpeedLabel
@onready var pause_button: Button = %PauseButton
@onready var hour_button: Button = %HourButton
@onready var day_button: Button = %DayButton
@onready var week_button: Button = %WeekButton
@onready var page_title: Label = %PageTitle
@onready var page_description: Label = %PageDescription


func _ready() -> void:
	GameState.time_changed.connect(_refresh_time)
	GameState.credits_changed.connect(_refresh_credits)
	GameState.speed_changed.connect(_refresh_speed)

	pause_button.pressed.connect(func() -> void: GameState.set_time_mode(GameState.TimeMode.PAUSED))
	hour_button.pressed.connect(func() -> void: GameState.set_time_mode(GameState.TimeMode.HOUR))
	day_button.pressed.connect(func() -> void: GameState.set_time_mode(GameState.TimeMode.DAY))
	week_button.pressed.connect(func() -> void: GameState.set_time_mode(GameState.TimeMode.WEEK))

	%GroupButton.pressed.connect(_show_group)
	%GridButton.pressed.connect(_show_grid)
	%ZapButton.pressed.connect(_show_zap)
	%ProductionButton.pressed.connect(_show_productions)

	_refresh_all()
	_show_group()


func _refresh_all() -> void:
	_refresh_time()
	_refresh_credits(GameState.credits)
	_refresh_speed(GameState.time_mode)


func _refresh_time() -> void:
	date_label.text = GameState.get_date_text()
	week_label.text = GameState.get_week_text()
	time_label.text = GameState.get_time_text()


func _refresh_credits(new_value: int) -> void:
	credits_label.text = "%s CC" % _format_number(new_value)


func _refresh_speed(_new_mode: int) -> void:
	speed_label.text = "Vitesse : %s" % GameState.get_speed_text()
	pause_button.disabled = GameState.time_mode == GameState.TimeMode.PAUSED
	hour_button.disabled = GameState.time_mode == GameState.TimeMode.HOUR
	day_button.disabled = GameState.time_mode == GameState.TimeMode.DAY
	week_button.disabled = GameState.time_mode == GameState.TimeMode.WEEK


func _show_group() -> void:
	page_title.text = "Notre groupe"
	page_description.text = "Votre groupe démarre avec 1 200 CC. La création et la gestion de votre première chaîne seront ajoutées dans la prochaine étape."


func _show_grid() -> void:
	page_title.text = "Grille TV"
	page_description.text = "Ici sera construite la grille de votre chaîne, du lundi au dimanche, avec 48 cases de 30 minutes par jour."


func _show_zap() -> void:
	page_title.text = "Zap'Chaine"
	page_description.text = "Le guide global affichera les programmes de toutes les chaînes présentes dans la partie."


func _show_productions() -> void:
	page_title.text = "Productions"
	page_description.text = "Cette section accueillera les productions du groupe, leurs durées, leurs thèmes et leur avancement."


func _format_number(value: int) -> String:
	var text := str(value)
	var result := ""
	while text.length() > 3:
		result = " " + text.right(3) + result
		text = text.left(text.length() - 3)
	return text + result
