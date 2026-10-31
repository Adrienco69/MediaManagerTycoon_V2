extends Control

const UIThemeManagerScript = preload("res://scripts/ui/ui_theme_manager.gd")
const StartScreenGradientScript = preload("res://scripts/ui/start_screen_gradient.gd")
const TopBarLayoutScript = preload("res://scripts/ui/top_bar_layout.gd")
const NavigationButtonStateScript = preload("res://scripts/ui/navigation_button_state.gd")
const GroupPageControllerScript = preload("res://scripts/ui/group_page_controller.gd")

@onready var background: ColorRect = $Background
@onready var start_screen: Control = %StartScreen
@onready var game_ui: Control = %GameUI
@onready var player_name_input: LineEdit = %PlayerNameInput
@onready var company_name_input: LineEdit = %CompanyNameInput
@onready var start_game_button: Button = %StartGameButton
@onready var start_error_label: Label = %StartErrorLabel

@onready var game_title: Label = $GameUI/RootVBox/TopBar/TopMargin/TopHBox/GameTitle
@onready var credits_label: Label = %CreditsLabel
@onready var date_container: VBoxContainer = $GameUI/RootVBox/TopBar/TopMargin/TopHBox/DateVBox
@onready var date_label: Label = %DateLabel
@onready var week_label: Label = %WeekLabel
@onready var time_label: Label = %TimeLabel
@onready var speed_label: Label = %SpeedLabel
@onready var pause_button: Button = %PauseButton
@onready var hour_button: Button = %HourButton
@onready var day_button: Button = %DayButton
@onready var week_button: Button = %WeekButton
@onready var group_button: Button = %GroupButton
@onready var grid_button: Button = %GridButton
@onready var zap_button: Button = %ZapButton
@onready var production_button: Button = %ProductionButton
@onready var content_container: VBoxContainer = $GameUI/RootVBox/MainPanel/ContentMargin/ContentVBox
@onready var page_title: Label = %PageTitle
@onready var page_description: Label = %PageDescription
@onready var start_title: Label = $StartScreen/Center/Panel/Margin/VBox/Title

var _last_theme_day_key: int = -1


func _ready() -> void:
	_setup_start_screen_gradient()
	TopBarLayoutScript.place_speed_controls_under_date(
		speed_label,
		week_label,
		date_container,
		credits_label,
		date_label,
		time_label,
		pause_button,
		hour_button,
		day_button,
		week_button
	)
	_connect_game_signals()
	_connect_buttons()
	_refresh_all()

	if GameState.has_started_game():
		_show_game_ui()
	else:
		_show_start_screen()


func _setup_start_screen_gradient() -> void:
	var old_vertical: CanvasItem = start_screen.get_node_or_null("MonthGradient") as CanvasItem
	var old_diagonal: CanvasItem = start_screen.get_node_or_null("MonthGradientDiagonal") as CanvasItem

	if old_vertical != null:
		old_vertical.visible = false
	if old_diagonal != null:
		old_diagonal.visible = false

	var gradient_layer: Control = StartScreenGradientScript.new() as Control
	gradient_layer.name = "AlternatingMonthGradient"
	start_screen.add_child(gradient_layer)
	gradient_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_screen.move_child(gradient_layer, 0)


func _connect_game_signals() -> void:
	GameState.time_changed.connect(_refresh_time)
	GameState.credits_changed.connect(_refresh_credits)
	GameState.speed_changed.connect(_refresh_speed)
	GameState.identity_changed.connect(_on_identity_changed)


func _connect_buttons() -> void:
	start_game_button.pressed.connect(_start_new_game)
	player_name_input.text_submitted.connect(_on_identity_text_submitted)
	company_name_input.text_submitted.connect(_on_identity_text_submitted)

	pause_button.pressed.connect(_on_pause_pressed)
	hour_button.pressed.connect(_on_hour_pressed)
	day_button.pressed.connect(_on_day_pressed)
	week_button.pressed.connect(_on_week_pressed)

	group_button.pressed.connect(_show_group)
	grid_button.pressed.connect(_show_grid)
	zap_button.pressed.connect(_show_zap)
	production_button.pressed.connect(_show_productions)


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
	var new_player_name: String = player_name_input.text.strip_edges()
	var new_company_name: String = company_name_input.text.strip_edges()

	if new_player_name.is_empty() or new_company_name.is_empty():
		start_error_label.text = "Renseigne le nom du joueur et le nom de la société."
		return

	GameState.start_new_game(new_player_name, new_company_name)
	_show_game_ui()


func _on_identity_changed(_player_name: String, _company_name: String) -> void:
	if game_ui.visible:
		_show_group()


func _on_first_channel_create_requested(channel_name: String) -> void:
	if GameState.create_first_channel(channel_name):
		call_deferred("_show_group")


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
	var day_key: int = (GameState.year * 1000) + (GameState.week_in_year * 10) + GameState.day_in_week
	if day_key == _last_theme_day_key:
		return

	_last_theme_day_key = day_key
	var weeks_in_month: int = int(GameState.MONTHS[GameState.month_index]["weeks"])
	var white_labels: Array[Label] = [
		game_title,
		credits_label,
		date_label,
		week_label,
		time_label,
		speed_label,
		page_title,
		page_description,
		start_title
	]

	UIThemeManagerScript.apply_calendar_theme(
		self,
		background,
		white_labels,
		GameState.month_index,
		GameState.get_day_of_month(),
		weeks_in_month
	)


func _refresh_credits(new_value: int) -> void:
	credits_label.text = "%s CC" % _format_number(new_value)


func _refresh_speed(_new_mode: int) -> void:
	speed_label.text = "Vitesse : %s" % GameState.get_speed_text()
	pause_button.disabled = GameState.time_mode == GameState.TimeMode.PAUSED
	hour_button.disabled = GameState.time_mode == GameState.TimeMode.HOUR
	day_button.disabled = GameState.time_mode == GameState.TimeMode.DAY
	week_button.disabled = GameState.time_mode == GameState.TimeMode.WEEK


func _show_group() -> void:
	NavigationButtonStateScript.apply(_get_navigation_buttons(), group_button)
	page_title.text = GameState.company_name
	GroupPageControllerScript.render(
		content_container,
		page_description,
		GameState.player_name,
		GameState.get_first_channel(),
		_on_first_channel_create_requested
	)


func _show_grid() -> void:
	_prepare_standard_page()
	NavigationButtonStateScript.apply(_get_navigation_buttons(), grid_button)
	page_title.text = "Grille TV"
	page_description.text = "Ici sera construite la grille de votre chaîne, du lundi au dimanche, avec 48 cases de 30 minutes par jour."


func _show_zap() -> void:
	_prepare_standard_page()
	NavigationButtonStateScript.apply(_get_navigation_buttons(), zap_button)
	page_title.text = "Zap'Chaine"
	page_description.text = "Le guide global affichera les programmes de toutes les chaînes présentes dans la partie."


func _show_productions() -> void:
	_prepare_standard_page()
	NavigationButtonStateScript.apply(_get_navigation_buttons(), production_button)
	page_title.text = "Productions"
	page_description.text = "Cette section accueillera les productions du groupe, leurs durées, leurs thèmes et leur avancement."


func _prepare_standard_page() -> void:
	GroupPageControllerScript.clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _get_navigation_buttons() -> Array[Button]:
	return [
		group_button,
		grid_button,
		zap_button,
		production_button
	]


func _format_number(value: int) -> String:
	var text: String = str(value)
	var result: String = ""
	while text.length() > 3:
		result = " " + text.right(3) + result
		text = text.left(text.length() - 3)
	return text + result
