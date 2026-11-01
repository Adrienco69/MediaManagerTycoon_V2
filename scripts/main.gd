extends Control

const UIThemeManagerScript = preload("res://scripts/ui/ui_theme_manager.gd")
const StartScreenGradientScript = preload("res://scripts/ui/start_screen_gradient.gd")
const StartMenuControllerScript = preload("res://scripts/ui/start_menu_controller.gd")
const GameHeaderActionsScript = preload("res://scripts/ui/game_header_actions.gd")
const SaveGameManagerScript = preload("res://scripts/core/save_game_manager.gd")
const TopBarLayoutScript = preload("res://scripts/ui/top_bar_layout.gd")
const NavigationButtonStateScript = preload("res://scripts/ui/navigation_button_state.gd")
const GroupPageControllerScript = preload("res://scripts/ui/group_page_controller.gd")
const TVGridPageControllerScript = preload("res://scripts/ui/tv_grid_page_controller.gd")
const ZapPageControllerScript = preload("res://scripts/ui/zap_page_controller.gd")
const ProductionPageControllerScript = preload("res://scripts/ui/production_page_controller.gd")
const ProductionCreationPageScript = preload("res://scripts/ui/production_creation_page.gd")
const LibraryPageControllerScript = preload("res://scripts/ui/library_page_controller.gd")
const LibraryProgramDetailControllerScript = preload("res://scripts/ui/library_program_detail_controller.gd")
const MainContentScrollScript = preload("res://scripts/ui/main_content_scroll.gd")

@onready var background: ColorRect = $Background
@onready var start_screen: Control = %StartScreen
@onready var home_panel: Control = %HomePanel
@onready var new_game_panel: Control = $StartScreen/Center/Panel
@onready var game_ui: Control = %GameUI
@onready var new_game_menu_button: Button = %NewGameMenuButton
@onready var load_game_button: Button = %LoadGameButton
@onready var back_to_home_button: Button = %BackToHomeButton
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
@onready var library_button: Button = %LibraryButton
@onready var content_margin: MarginContainer = $GameUI/RootVBox/MainPanel/ContentMargin
@onready var content_container: VBoxContainer = $GameUI/RootVBox/MainPanel/ContentMargin/ContentVBox
@onready var page_title: Label = %PageTitle
@onready var page_description: Label = %PageDescription
@onready var home_title: Label = %HomeTitle
@onready var start_title: Label = $StartScreen/Center/Panel/Margin/VBox/Title

var _last_theme_day_key: int = -1
var _main_content_scroll: ScrollContainer
var _save_button: Button
var _main_menu_button: Button
var _save_status_label: Label
var _continue_game_button: Button
var _quit_game_button: Button
var _delete_save_button: Button
var _delete_save_dialog: ConfirmationDialog


func _ready() -> void:
	_setup_start_screen_gradient()
	_main_content_scroll = MainContentScrollScript.setup(content_margin, content_container)
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

	var header_actions: Dictionary = GameHeaderActionsScript.build(
		game_title,
		_save_game,
		_return_to_main_menu
	)
	_save_button = header_actions.get("save_button") as Button
	_main_menu_button = header_actions.get("menu_button") as Button
	_save_status_label = header_actions.get("status_label") as Label
	_continue_game_button = StartMenuControllerScript.ensure_continue_button(home_panel, _continue_game)
	_quit_game_button = StartMenuControllerScript.ensure_quit_button(home_panel, _quit_game)
	_setup_delete_save_controls()

	_connect_game_signals()
	_connect_buttons()
	_refresh_all()
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


func _setup_delete_save_controls() -> void:
	var vbox: VBoxContainer = home_panel.get_node("Margin/VBox") as VBoxContainer
	_delete_save_button = vbox.get_node_or_null("DeleteSaveButton") as Button
	if _delete_save_button == null:
		_delete_save_button = Button.new()
		_delete_save_button.name = "DeleteSaveButton"
		_delete_save_button.text = "Supprimer la sauvegarde"
		_delete_save_button.custom_minimum_size = Vector2(0, 52)
		_delete_save_button.pressed.connect(_request_delete_save)
		vbox.add_child(_delete_save_button)
		if _quit_game_button != null:
			vbox.move_child(_delete_save_button, _quit_game_button.get_index())

	_delete_save_dialog = ConfirmationDialog.new()
	_delete_save_dialog.name = "DeleteSaveDialog"
	_delete_save_dialog.title = "Supprimer la sauvegarde"
	_delete_save_dialog.dialog_text = "Supprimer définitivement cette sauvegarde ? Cette action est irréversible."
	_delete_save_dialog.ok_button_text = "Supprimer"
	_delete_save_dialog.cancel_button_text = "Annuler"
	_delete_save_dialog.confirmed.connect(_confirm_delete_save)
	start_screen.add_child(_delete_save_dialog)


func _connect_game_signals() -> void:
	GameState.time_changed.connect(_refresh_time)
	GameState.credits_changed.connect(_refresh_credits)
	GameState.speed_changed.connect(_refresh_speed)
	GameState.identity_changed.connect(_on_identity_changed)
	GameState.productions_changed.connect(_on_productions_changed)


func _connect_buttons() -> void:
	new_game_menu_button.pressed.connect(_show_new_game_form)
	load_game_button.pressed.connect(_load_game)
	back_to_home_button.pressed.connect(_show_start_screen)
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
	library_button.pressed.connect(_show_library)


func _show_start_screen() -> void:
	GameState.set_time_mode(GameState.TimeMode.PAUSED)
	start_screen.visible = true
	game_ui.visible = false
	var has_save: bool = SaveGameManagerScript.has_save()
	StartMenuControllerScript.show_home(
		home_panel,
		new_game_panel,
		load_game_button,
		start_error_label,
		has_save
	)
	if _delete_save_button != null:
		_delete_save_button.visible = has_save
		_delete_save_button.disabled = not has_save
	if _continue_game_button != null:
		_continue_game_button.visible = GameState.has_started_game()
	if _save_status_label != null:
		_save_status_label.text = ""
	if _continue_game_button != null and _continue_game_button.visible:
		_continue_game_button.grab_focus()
	else:
		new_game_menu_button.grab_focus()


func _show_new_game_form() -> void:
	StartMenuControllerScript.show_new_game(
		home_panel,
		new_game_panel,
		player_name_input,
		start_error_label
	)


func _show_game_ui() -> void:
	start_screen.visible = false
	game_ui.visible = true
	if _save_status_label != null:
		_save_status_label.text = ""
	_show_group()


func _continue_game() -> void:
	if not GameState.has_started_game():
		return
	start_screen.visible = false
	game_ui.visible = true
	if _save_status_label != null:
		_save_status_label.text = ""
	# La partie reste volontairement en pause après un passage par le menu.
	# L'écran qui était affiché est conservé tel quel en mémoire.


func _on_identity_text_submitted(_text: String) -> void:
	_start_new_game()


func _start_new_game() -> void:
	var new_player_name: String = player_name_input.text.strip_edges()
	var new_company_name: String = company_name_input.text.strip_edges()

	if new_player_name.is_empty() or new_company_name.is_empty():
		start_error_label.text = "Renseigne le nom du joueur et le nom de la société."
		return

	GameState.start_new_game(new_player_name, new_company_name)
	_last_theme_day_key = -1
	_refresh_all()
	_show_game_ui()


func _load_game() -> void:
	var save_data: Dictionary = SaveGameManagerScript.load_game()
	if save_data.is_empty():
		load_game_button.disabled = true
		load_game_button.tooltip_text = "Sauvegarde introuvable ou invalide."
		return

	if not GameState.load_save_data(save_data):
		load_game_button.disabled = true
		load_game_button.tooltip_text = "La sauvegarde ne peut pas être chargée."
		return

	_last_theme_day_key = -1
	_refresh_all()
	_show_game_ui()


func _save_game() -> void:
	if not GameState.has_started_game():
		return

	var saved: bool = SaveGameManagerScript.save_game(GameState.get_save_data())
	if _save_status_label != null:
		_save_status_label.text = "Sauvegardé" if saved else "Erreur sauvegarde"


func _request_delete_save() -> void:
	if not SaveGameManagerScript.has_save() or _delete_save_dialog == null:
		return
	_delete_save_dialog.popup_centered()


func _confirm_delete_save() -> void:
	var deleted: bool = SaveGameManagerScript.delete_save()
	if not deleted:
		start_error_label.text = "Impossible de supprimer la sauvegarde."
		return
	_show_start_screen()


func _return_to_main_menu() -> void:
	GameState.set_time_mode(GameState.TimeMode.PAUSED)
	_show_start_screen()


func _quit_game() -> void:
	get_tree().quit()


func _on_identity_changed(_player_name: String, _company_name: String) -> void:
	if game_ui.visible:
		_show_group()


func _on_first_channel_create_requested(channel_name: String) -> void:
	if GameState.create_first_channel(channel_name):
		call_deferred("_show_group")


func _on_productions_changed() -> void:
	if game_ui.visible and page_title.text == "Productions":
		call_deferred("_show_productions")


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
		home_title,
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
	_clear_dynamic_pages()
	_scroll_main_to_top()
	NavigationButtonStateScript.apply(_get_navigation_buttons(), group_button)
	page_title.text = GameState.company_name
	GroupPageControllerScript.render(
		content_container,
		page_description,
		GameState.player_name,
		GameState.company_name,
		GameState.get_first_channel(),
		_on_first_channel_create_requested,
		_show_grid
	)


func _show_grid() -> void:
	_clear_dynamic_pages()
	_scroll_main_to_top()
	NavigationButtonStateScript.apply(_get_navigation_buttons(), grid_button)
	page_title.text = "Grille TV"

	var channel: Dictionary = GameState.get_first_channel()
	if channel.is_empty():
		page_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page_description.text = "Créez d'abord votre première chaîne."
		return

	TVGridPageControllerScript.render(
		content_container,
		page_description,
		channel,
		true,
		GameState.get_group_programs(),
		Callable(),
		_show_grid_program
	)


func _show_grid_program(program: Dictionary) -> void:
	_clear_dynamic_pages()
	_scroll_main_to_top()
	NavigationButtonStateScript.apply(_get_navigation_buttons(), grid_button)

	var program_id: String = String(program.get("id", ""))
	var current_program: Dictionary = GameState.get_program(program_id)
	if current_program.is_empty():
		current_program = program

	page_title.text = "Programme | %s" % String(current_program.get("name", "Programme"))
	LibraryProgramDetailControllerScript.render(
		content_container,
		page_description,
		current_program,
		_show_grid,
		"← Retour à la Grille TV"
	)


func _show_zap() -> void:
	_clear_dynamic_pages()
	_scroll_main_to_top()
	NavigationButtonStateScript.apply(_get_navigation_buttons(), zap_button)
	page_title.text = "Zap'Chaine"
	ZapPageControllerScript.render(
		content_container,
		page_description,
		GameState.get_zap_channels(),
		_show_zap_channel_schedule
	)


func _show_zap_channel_schedule(channel: Dictionary) -> void:
	_clear_dynamic_pages()
	_scroll_main_to_top()
	NavigationButtonStateScript.apply(_get_navigation_buttons(), zap_button)
	page_title.text = "Zap'Chaine | %s" % String(channel.get("name", ""))

	var captured_channel: Dictionary = channel.duplicate(true)
	TVGridPageControllerScript.render(
		content_container,
		page_description,
		channel,
		false,
		[],
		_show_zap,
		_show_zap_program.bind(captured_channel)
	)


func _show_zap_program(program: Dictionary, channel: Dictionary) -> void:
	_clear_dynamic_pages()
	_scroll_main_to_top()
	NavigationButtonStateScript.apply(_get_navigation_buttons(), zap_button)

	page_title.text = "Programme | %s" % String(program.get("name", "Programme"))
	LibraryProgramDetailControllerScript.render(
		content_container,
		page_description,
		program,
		_show_zap_channel_schedule.bind(channel.duplicate(true)),
		"← Retour à Zap'Chaine | %s" % String(channel.get("name", ""))
	)


func _show_productions() -> void:
	_clear_dynamic_pages()
	_scroll_main_to_top()
	NavigationButtonStateScript.apply(_get_navigation_buttons(), production_button)
	page_title.text = "Productions"

	if not GameState.has_player_channel():
		page_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page_description.text = "Créez d'abord votre première chaîne."
		return

	ProductionPageControllerScript.render(
		content_container,
		page_description,
		GameState.get_active_productions(),
		_on_create_production_requested
	)


func _show_library() -> void:
	_clear_dynamic_pages()
	_scroll_main_to_top()
	NavigationButtonStateScript.apply(_get_navigation_buttons(), library_button)
	page_title.text = "Bibliothèque"

	if not GameState.has_player_channel():
		page_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page_description.text = "Créez d'abord votre première chaîne."
		return

	LibraryPageControllerScript.render(
		content_container,
		page_description,
		GameState.get_group_programs(),
		_show_library_program
	)


func _show_library_program(program: Dictionary) -> void:
	_clear_dynamic_pages()
	_scroll_main_to_top()
	NavigationButtonStateScript.apply(_get_navigation_buttons(), library_button)

	var program_id: String = String(program.get("id", ""))
	var current_program: Dictionary = GameState.get_program(program_id)
	if current_program.is_empty():
		current_program = program

	page_title.text = "Bibliothèque | %s" % String(current_program.get("name", "Programme"))
	LibraryProgramDetailControllerScript.render(
		content_container,
		page_description,
		current_program,
		_show_library
	)


func _on_create_production_requested() -> void:
	_clear_dynamic_pages()
	_scroll_main_to_top()
	NavigationButtonStateScript.apply(_get_navigation_buttons(), production_button)
	page_title.text = "Productions | Nouvelle production"
	ProductionCreationPageScript.render(
		content_container,
		page_description,
		_show_productions,
		_start_production_from_form
	)


func _start_production_from_form(spec: Dictionary) -> String:
	var error_text: String = GameState.create_production(spec)
	if error_text.is_empty():
		call_deferred("_show_productions")
	return error_text


func _clear_dynamic_pages() -> void:
	GroupPageControllerScript.clear(content_container)
	TVGridPageControllerScript.clear(content_container)
	ZapPageControllerScript.clear(content_container)
	ProductionPageControllerScript.clear(content_container)
	ProductionCreationPageScript.clear(content_container)
	LibraryPageControllerScript.clear(content_container)
	LibraryProgramDetailControllerScript.clear(content_container)


func _scroll_main_to_top() -> void:
	if _main_content_scroll != null:
		MainContentScrollScript.scroll_to_top(_main_content_scroll)


func _get_navigation_buttons() -> Array[Button]:
	return [
		group_button,
		grid_button,
		zap_button,
		production_button,
		library_button
	]


func _format_number(value: int) -> String:
	var text: String = str(value)
	var result: String = ""
	while text.length() > 3:
		result = " " + text.right(3) + result
		text = text.left(text.length() - 3)
	return text + result