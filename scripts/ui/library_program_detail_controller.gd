class_name LibraryProgramDetailController
extends RefCounted

const ProgramStatusScript = preload("res://scripts/ui/library_program_status.gd")
const EpisodeTableScript = preload("res://scripts/ui/library_program_episode_table.gd")
const SeasonManagerScript = preload("res://scripts/ui/library_season_manager.gd")

const DYNAMIC_NODE_NAME: String = "LibraryProgramDetailDynamic"
const INFO_WIDTHS: Array[float] = [230.0, 420.0]
const NAV_BUTTON_HEIGHT: float = 40.0


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	program: Dictionary,
	on_back: Callable,
	back_button_text: String = "← Retour à la Bibliothèque",
	on_manage_seasons: Callable = Callable()
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Fiche du programme | informations et historique des diffusions."

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.add_theme_constant_override("separation", 14)
	content_container.add_child(dynamic)

	var nav_row: HBoxContainer = HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", 8)
	dynamic.add_child(nav_row)

	var back_button: Button = Button.new()
	back_button.text = back_button_text
	back_button.custom_minimum_size = Vector2(0, NAV_BUTTON_HEIGHT)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back_button.pressed.connect(on_back)
	nav_row.add_child(back_button)

	var info_button: Button = Button.new()
	info_button.text = "Infos pratiques"
	info_button.custom_minimum_size = Vector2(180, NAV_BUTTON_HEIGHT)
	nav_row.add_child(info_button)

	var production_diffusion_button: Button = Button.new()
	production_diffusion_button.text = "Diffusion par épisodes"
	production_diffusion_button.custom_minimum_size = Vector2(220, NAV_BUTTON_HEIGHT)
	nav_row.add_child(production_diffusion_button)

	var season_diffusion_button: Button = Button.new()
	season_diffusion_button.text = "Diffusion par saison"
	season_diffusion_button.custom_minimum_size = Vector2(210, NAV_BUTTON_HEIGHT)
	nav_row.add_child(season_diffusion_button)

	var tab_content: VBoxContainer = VBoxContainer.new()
	tab_content.add_theme_constant_override("separation", 12)
	dynamic.add_child(tab_content)

	var callbacks: Dictionary = {}
	var manage_seasons_callable: Callable = on_manage_seasons
	var is_zap_read_only: bool = back_button_text.contains("Zap'Chaine")

	callbacks["show_info"] = func() -> void:
		_clear_holder(tab_content)
		page_description.text = "Fiche du programme | informations et historique des diffusions."
		info_button.disabled = true
		production_diffusion_button.disabled = false
		season_diffusion_button.disabled = false
		var current_program: Dictionary = GameState.get_program(String(program.get("id", "")))
		if current_program.is_empty():
			current_program = program
		_build_program_info(tab_content, current_program, manage_seasons_callable)

	if not is_zap_read_only and not manage_seasons_callable.is_valid() and _can_manage_seasons(program):
		manage_seasons_callable = func() -> void:
			_clear_holder(tab_content)
			info_button.disabled = false
			production_diffusion_button.disabled = false
			season_diffusion_button.disabled = false
			var current_program: Dictionary = GameState.get_program(String(program.get("id", "")))
			if current_program.is_empty():
				current_program = program.duplicate(true)
			SeasonManagerScript.render(
				tab_content,
				page_description,
				current_program,
				func() -> void:
					var show_info_callable: Callable = callbacks.get("show_info", Callable())
					if show_info_callable.is_valid():
						show_info_callable.call(),
				func(season_number: int, codes: Array[int]) -> String:
					var error_text: String = GameState._production_manager.set_editorial_season(
						String(current_program.get("id", "")),
						season_number,
						codes
					)
					if error_text.is_empty():
						GameState.programs_changed.emit()
					return error_text
			)

	var show_info: Callable = callbacks["show_info"] as Callable

	var show_production_diffusion: Callable = func() -> void:
		_clear_holder(tab_content)
		page_description.text = "Diffusions classées selon le code prod des unités."
		info_button.disabled = false
		production_diffusion_button.disabled = true
		season_diffusion_button.disabled = false
		var current_program: Dictionary = GameState.get_program(String(program.get("id", "")))
		if current_program.is_empty():
			current_program = program
		EpisodeTableScript.build_by_production(tab_content, current_program)

	var show_season_diffusion: Callable = func() -> void:
		_clear_holder(tab_content)
		page_description.text = "Diffusions classées selon le découpage éditorial en saisons."
		info_button.disabled = false
		production_diffusion_button.disabled = false
		season_diffusion_button.disabled = true
		var current_program: Dictionary = GameState.get_program(String(program.get("id", "")))
		if current_program.is_empty():
			current_program = program
		EpisodeTableScript.build_by_season(tab_content, current_program)

	info_button.pressed.connect(show_info)
	production_diffusion_button.pressed.connect(show_production_diffusion)
	season_diffusion_button.pressed.connect(show_season_diffusion)
	show_info.call()


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _build_program_info(parent: VBoxContainer, program: Dictionary, on_manage_seasons: Callable) -> void:
	var table: GridContainer = GridContainer.new()
	table.columns = 2
	table.add_theme_constant_override("h_separation", 0)
	table.add_theme_constant_override("v_separation", 0)
	parent.add_child(table)

	_add_info_row(table, "Programme", String(program.get("name", "")))
	_add_info_row(table, "Format", String(program.get("format", "")))
	_add_info_row(table, "Durée", "%d min" % int(program.get("duration_minutes", 0)))
	_add_info_row(table, "Unités disponibles", _get_available_unit_text(program))
	if _can_manage_seasons(program) and on_manage_seasons.is_valid():
		_add_season_info_row(table, _get_season_text(program), on_manage_seasons)
	else:
		_add_info_row(table, "Saison(s) éditoriale(s)", _get_season_text(program))
	_add_info_row(table, "État", ProgramStatusScript.get_text(program))


static func _can_manage_seasons(program: Dictionary) -> bool:
	var format_name: String = String(program.get("format", ""))
	if format_name == "Film" or format_name == "Téléfilm":
		return false
	return int(program.get("units_total", program.get("episodes_total", 0))) > 1


static func _add_season_info_row(table: GridContainer, value_text: String, on_manage_seasons: Callable) -> void:
	_add_panel_label(table, "Saison(s) éditoriale(s)", INFO_WIDTHS[0], true)

	var panel: PanelContainer = _create_panel(INFO_WIDTHS[1])
	table.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var value_label := Label.new()
	value_label.text = value_text
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value_label)

	var manage_button := Button.new()
	manage_button.text = "Gérer les saisons"
	manage_button.custom_minimum_size = Vector2(160, 34)
	manage_button.pressed.connect(on_manage_seasons)
	row.add_child(manage_button)


static func _get_available_unit_text(program: Dictionary) -> String:
	var total: int = int(program.get("units_total", program.get("episodes_total", 0)))
	var available: int = int(program.get("units_available", program.get("episodes_available", 0)))
	if total <= 0:
		return "Variable"
	if available == total:
		return str(available)
	return "%d / %d" % [available, total]


static func _get_season_text(program: Dictionary) -> String:
	var season_count: int = int(program.get("season_count", 0))
	if season_count > 0:
		if season_count == 1:
			return "1 saison"
		return "%d saisons" % season_count

	var season_data_value: Variant = program.get("seasons", [])
	if season_data_value is Array:
		var season_data: Array = season_data_value
		if not season_data.is_empty():
			if season_data.size() == 1:
				return "1 saison"
			return "%d saisons" % season_data.size()

	return "Aucune saison éditoriale créée"


static func _add_info_row(table: GridContainer, label_text: String, value_text: String) -> void:
	_add_panel_label(table, label_text, INFO_WIDTHS[0], true)
	_add_panel_label(table, value_text, INFO_WIDTHS[1], false)


static func _create_panel(width: float) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 44)
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.025)
	box.border_color = Color(1, 1, 1, 0.18)
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 7.0
	box.content_margin_bottom = 7.0
	panel.add_theme_stylebox_override("panel", box)
	return panel


static func _add_panel_label(table: GridContainer, text: String, width: float, is_header: bool) -> void:
	var panel: PanelContainer = _create_panel(width)
	table.add_child(panel)

	var label: Label = Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if is_header:
		label.add_theme_font_size_override("font_size", 16)
	panel.add_child(label)


static func _clear_holder(holder: VBoxContainer) -> void:
	SeasonManagerScript.clear(holder)
	for child: Node in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
