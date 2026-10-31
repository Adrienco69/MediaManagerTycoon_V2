extends Control

const CalendarTheme = preload("res://scripts/calendar_theme.gd")

@onready var background: ColorRect = $Background
@onready var start_screen: Control = %StartScreen
@onready var game_ui: Control = %GameUI
@onready var player_name_input: LineEdit = %PlayerNameInput
@onready var company_name_input: LineEdit = %CompanyNameInput
@onready var start_game_button: Button = %StartGameButton
@onready var start_error_label: Label = %StartErrorLabel
@onready var start_title: Label = $StartScreen/Center/Panel/Margin/VBox/Title

@onready var game_title: Label = $GameUI/RootVBox/TopBar/TopMargin/TopHBox/GameTitle
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

var _last_theme_day_key: int = -1


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
	_refresh_calendar_theme()


func _refresh_calendar_theme() -> void:
	var day_key := (GameState.year * 1000) + (GameState.week_in_year * 10) + GameState.day_in_week
	if day_key == _last_theme_day_key:
		return
	_last_theme_day_key = day_key

	var weeks_in_month: int = int(GameState.MONTHS[GameState.month_index]["weeks"])
	var palette := CalendarTheme.get_palette(
		GameState.month_index,
		GameState.get_day_of_month(),
		weeks_in_month
	)

	var background_color: Color = palette["background"]
	var surface_color: Color = palette["surface"]
	var surface_alt_color: Color = palette["surface_alt"]
	var accent_color: Color = palette["accent"]
	var accent_soft_color: Color = palette["accent_soft"]
	var text_color: Color = palette["text"]
	var muted_color: Color = palette["muted"]

	background.color = background_color

	var calendar_ui_theme := Theme.new()
	calendar_ui_theme.set_color("font_color", "Label", text_color)
	calendar_ui_theme.set_color("font_color", "Button", text_color)
	calendar_ui_theme.set_color("font_hover_color", "Button", text_color)
	calendar_ui_theme.set_color("font_pressed_color", "Button", text_color)
	calendar_ui_theme.set_color("font_disabled_color", "Button", muted_color.darkened(0.22))
	calendar_ui_theme.set_color("font_color", "LineEdit", text_color)
	calendar_ui_theme.set_color("font_placeholder_color", "LineEdit", muted_color)
	calendar_ui_theme.set_color("caret_color", "LineEdit", accent_soft_color)

	calendar_ui_theme.set_stylebox("panel", "PanelContainer", _make_box(surface_color, accent_color.darkened(0.45), 10, 1))
	calendar_ui_theme.set_stylebox("normal", "Button", _make_box(surface_alt_color, accent_color.darkened(0.35), 8, 1))
	calendar_ui_theme.set_stylebox("hover", "Button", _make_box(surface_alt_color.lightened(0.10), accent_color, 8, 1))
	calendar_ui_theme.set_stylebox("pressed", "Button", _make_box(accent_color.darkened(0.35), accent_soft_color, 8, 1))
	calendar_ui_theme.set_stylebox("disabled", "Button", _make_box(surface_color.darkened(0.10), surface_alt_color, 8, 1))
	calendar_ui_theme.set_stylebox("focus", "Button", _make_outline_box(accent_soft_color, 8, 2))
	calendar_ui_theme.set_stylebox("normal", "LineEdit", _make_box(surface_alt_color.darkened(0.08), accent_color.darkened(0.30), 8, 1))
	calendar_ui_theme.set_stylebox("focus", "LineEdit", _make_box(surface_alt_color, accent_soft_color, 8, 2))
	calendar_ui_theme.set_stylebox("separator", "HSeparator", _make_separator_box(accent_color.darkened(0.20)))

	theme = calendar_ui_theme

	game_title.add_theme_color_override("font_color", accent_soft_color)
	credits_label.add_theme_color_override("font_color", accent_soft_color)
	date_label.add_theme_color_override("font_color", accent_soft_color)
	time_label.add_theme_color_override("font_color", accent_soft_color)
	page_title.add_theme_color_override("font_color", accent_soft_color)
	start_title.add_theme_color_override("font_color", accent_soft_color)


func _make_box(background_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background_color
	box.border_color = border_color
	box.border_width_left = border_width
	box.border_width_top = border_width
	box.border_width_right = border_width
	box.border_width_bottom = border_width
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 8.0
	box.content_margin_bottom = 8.0
	return box


func _make_outline_box(border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.border_color = border_color
	box.border_width_left = border_width
	box.border_width_top = border_width
	box.border_width_right = border_width
	box.border_width_bottom = border_width
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	return box


func _make_separator_box(separator_color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = separator_color
	box.content_margin_top = 1.0
	box.content_margin_bottom = 1.0
	return box


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
