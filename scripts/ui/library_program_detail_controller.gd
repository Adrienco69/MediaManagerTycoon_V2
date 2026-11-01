class_name LibraryProgramDetailController
extends RefCounted

const ProgramStatusScript = preload("res://scripts/ui/library_program_status.gd")
const DYNAMIC_NODE_NAME: String = "LibraryProgramDetailDynamic"
const INFO_WIDTHS: Array[float] = [230.0, 420.0]
const HISTORY_WIDTHS: Array[float] = [110.0, 110.0, 240.0, 100.0, 220.0, 150.0]


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	program: Dictionary,
	on_back: Callable
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Fiche du programme | saisons, épisodes et historique des diffusions."

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.add_theme_constant_override("separation", 14)
	content_container.add_child(dynamic)

	var back_button: Button = Button.new()
	back_button.text = "← Retour à la Bibliothèque"
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back_button.pressed.connect(on_back)
	dynamic.add_child(back_button)

	_build_program_info(dynamic, program)

	var history_title: Label = Label.new()
	history_title.text = "Historique des diffusions"
	history_title.add_theme_font_size_override("font_size", 22)
	dynamic.add_child(history_title)

	_build_broadcast_history(dynamic, program)


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _build_program_info(parent: VBoxContainer, program: Dictionary) -> void:
	var table: GridContainer = GridContainer.new()
	table.columns = 2
	table.add_theme_constant_override("h_separation", 0)
	table.add_theme_constant_override("v_separation", 0)
	parent.add_child(table)

	_add_info_row(table, "Programme", String(program.get("name", "")))
	_add_info_row(table, "Format", String(program.get("format", "")))
	_add_info_row(table, "Durée", "%d min" % int(program.get("duration_minutes", 0)))
	_add_info_row(table, "Épisodes disponibles", _get_available_episode_text(program))
	_add_info_row(table, "Saison(s)", _get_season_text(program))
	_add_info_row(table, "État", ProgramStatusScript.get_text(program))


static func _build_broadcast_history(parent: VBoxContainer, program: Dictionary) -> void:
	var history_value: Variant = program.get("broadcast_history", [])
	var history: Array = []
	if history_value is Array:
		history = history_value

	if history.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Aucune diffusion enregistrée."
		parent.add_child(empty_label)
		return

	var table: GridContainer = GridContainer.new()
	table.columns = 6
	table.add_theme_constant_override("h_separation", 0)
	table.add_theme_constant_override("v_separation", 0)
	parent.add_child(table)

	_add_history_cell(table, "Saison", 0, true)
	_add_history_cell(table, "Épisode", 1, true)
	_add_history_cell(table, "Date", 2, true)
	_add_history_cell(table, "Heure", 3, true)
	_add_history_cell(table, "Chaîne", 4, true)
	_add_history_cell(table, "Diffusion", 5, true)

	for item_value: Variant in history:
		if not item_value is Dictionary:
			continue
		var item: Dictionary = item_value
		_add_history_cell(table, _get_history_season(item), 0, false)
		_add_history_cell(table, _get_history_episode(item), 1, false)
		_add_history_cell(table, String(item.get("date", "Date inconnue")), 2, false)
		_add_history_cell(table, String(item.get("time", "--:--")), 3, false)
		_add_history_cell(table, String(item.get("channel", "Chaîne inconnue")), 4, false)
		_add_history_cell(table, String(item.get("type", "Diffusion")), 5, false)


static func _get_available_episode_text(program: Dictionary) -> String:
	var total: int = int(program.get("episodes_total", 0))
	var available: int = int(program.get("episodes_available", 0))
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

	return "Saison non renseignée"


static func _get_history_season(item: Dictionary) -> String:
	var season_number: int = int(item.get("season", 0))
	if season_number <= 0:
		return "Non renseignée"
	return "S%d" % season_number


static func _get_history_episode(item: Dictionary) -> String:
	var episode_number: int = int(item.get("episode", 0))
	if episode_number <= 0:
		return "—"
	return "E%d" % episode_number


static func _add_info_row(table: GridContainer, label_text: String, value_text: String) -> void:
	_add_panel_label(table, label_text, INFO_WIDTHS[0], true)
	_add_panel_label(table, value_text, INFO_WIDTHS[1], false)


static func _add_history_cell(table: GridContainer, text: String, column: int, is_header: bool) -> void:
	_add_panel_label(table, text, HISTORY_WIDTHS[column], is_header)


static func _add_panel_label(table: GridContainer, text: String, width: float, is_header: bool) -> void:
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
	table.add_child(panel)

	var label: Label = Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if is_header:
		label.add_theme_font_size_override("font_size", 16)
	panel.add_child(label)
