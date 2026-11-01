class_name LibraryPageController
extends RefCounted

const DYNAMIC_NODE_NAME: String = "LibraryDynamic"
const COLUMN_WIDTHS: Array[float] = [300.0, 180.0, 120.0, 170.0, 170.0]


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	programs: Array[Dictionary],
	on_open_program: Callable
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Tous les programmes possédés par votre groupe. Cliquez sur un titre pour ouvrir sa fiche."

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.add_theme_constant_override("separation", 12)
	content_container.add_child(dynamic)

	var count_label: Label = Label.new()
	count_label.text = "%d programme(s) dans la Bibliothèque" % programs.size()
	dynamic.add_child(count_label)

	_build_table(dynamic, programs, on_open_program)


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _build_table(
	parent: VBoxContainer,
	programs: Array[Dictionary],
	on_open_program: Callable
) -> void:
	if programs.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Votre Bibliothèque est vide."
		parent.add_child(empty_label)
		return

	var table: GridContainer = GridContainer.new()
	table.columns = 5
	table.add_theme_constant_override("h_separation", 0)
	table.add_theme_constant_override("v_separation", 0)
	parent.add_child(table)

	_add_cell(table, "Programme", 0, true)
	_add_cell(table, "Format", 1, true)
	_add_cell(table, "Durée", 2, true)
	_add_cell(table, "Épisodes disponibles", 3, true)
	_add_cell(table, "État", 4, true)

	for program: Dictionary in programs:
		_add_program_button_cell(table, program, on_open_program)
		_add_cell(table, String(program.get("format", "")), 1, false)
		_add_cell(table, "%d min" % int(program.get("duration_minutes", 0)), 2, false)
		_add_cell(table, _get_available_episode_text(program), 3, false)
		_add_cell(table, _get_library_status(program), 4, false)


static func _get_available_episode_text(program: Dictionary) -> String:
	var total: int = int(program.get("episodes_total", 0))
	var available: int = int(program.get("episodes_available", 0))
	if total <= 0:
		return "Variable"
	if available == total:
		return str(available)
	return "%d / %d" % [available, total]


static func _get_library_status(program: Dictionary) -> String:
	var status: String = String(program.get("status", "Disponible"))
	if status == "Production en cours":
		return "Disponible + production en cours"
	return status


static func _add_program_button_cell(
	table: GridContainer,
	program: Dictionary,
	on_open_program: Callable
) -> void:
	var panel: PanelContainer = _create_cell_panel(0)
	table.add_child(panel)

	var button: Button = Button.new()
	button.text = String(program.get("name", ""))
	button.tooltip_text = "Ouvrir la fiche de %s" % button.text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 34)
	button.pressed.connect(on_open_program.bind(program.duplicate(true)))
	panel.add_child(button)


static func _add_cell(table: GridContainer, text: String, column: int, is_header: bool) -> void:
	var panel: PanelContainer = _create_cell_panel(column)
	table.add_child(panel)

	var label: Label = Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if is_header:
		label.add_theme_font_size_override("font_size", 16)
	panel.add_child(label)


static func _create_cell_panel(column: int) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(COLUMN_WIDTHS[column], 44)

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
