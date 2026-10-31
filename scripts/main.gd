extends Control

@onready var start_screen: Control = %StartScreen
@onready var game_ui: Control = %GameUI
@onready var player_name_input: LineEdit = %PlayerNameInput
@onready var company_name_input: LineEdit = %CompanyNameInput
@onready var start_game_button: Button = %StartGameButton
@onready var start_error_label: Label = %StartErrorLabel

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
	GameState.identity_changed.connect(_on_identity_changed)

	start_game_button.pressed.connect(_start_new_game)
	player_name_input.text_submitted.connect(_on_identity_text_submitted)
	company_name_input.text_submitted.connect(_on_identity_text_submitted)

	pause_button.pressed.connect(_on_pause_pressed)
	hour_button.pressed.connect(_on_hour_pressed)
	day_button.pressed.connect(_on_day_pressed)
	week_button.pressed.connect(_on_week_pressed)

	%GroupButton.pressed.connect(_show_group)
	%GridButton.pressed.connect(_show_grid)
	%ZapButton.pressed.connect(_show_zap)
	%ProductionButton.pressed.connect(_show_productions)

	_refresh_all()

	if GameState.has_started_game():
		_show_game_ui()
	else:
		_show_start_screen()


func _show_start_screen() -> void:
	GameState.set_time_mode(GameState.TimeMode.PAUSED)
	start_screen.visible = true
	game_ui.visible = false
	start_error_label.text = ""
	player_name_input.grab_focus()


func _show_game_ui() -> void:
	start_screen.visible = false
	game_ui.visible = true
	_show_group()


func _on_identity_text_submitted(_text: String) -> void:
	_start_new_game()


func _start_new_game() -> void:
	var new_player_name := player_name_input.text.strip_edges()
	var new_company_name := company_name_input.text.strip_edges()

	if new_player_name.is_empty() or new_company_name.is_empty():
		start_error_label.text = "Renseigne le nom du joueur et le nom de la société."
		return

	GameState.start_new_game(new_player_name, new_company_name)
	_show_game_ui()


func _on_identity_changed(_player_name: String, _company_name: String) -> void:
	if game_ui.visible:
		_show_group()


func _on_pause_pressed() -> void:
	GameState.set_time_mode(GameState.TimeMode.PAUSED)


func _on_hour_pressed() -> void:
	GameState.set_time_mode(GameState.TimeMode.HOUR)


func _on_day_pressed() -> void:
	GameState.set_time_mode(GameState.TimeMode.DAY)


func _on_week_pressed() -> void:
	GameState.set_time_mode(GameState.TimeMode.WEEK)


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
	page_title.text = GameState.company_name
	page_description.text = "Dirigeant : %s\nCapital de départ : 1 200 CC\n\nLa prochaine étape sera la création de votre première chaîne de télévision." % GameState.player_name


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
