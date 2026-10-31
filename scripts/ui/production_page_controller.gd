class_name ProductionPageController
extends RefCounted

const DYNAMIC_NODE_NAME: String = "ProductionDynamic"
const COLUMN_WIDTHS: Array[float] = [300.0, 180.0, 120.0, 150.0, 190.0]


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	programs: Array[Dictionary],
	on_create_production: Callable
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Programmes appartenant au groupe et productions en cours."

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.add_theme_constant_override("separation", 12)
	content_container.add_child(dynamic)

	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	dynamic.add_child(actions)

	var create_button: Button = Button.new()
	create_button.text = "Créer une production"
	create_button.custom_minimum_size = Vector2(190, 42)
	create_button.pressed.connect(on_create_production)
	actions.add_child(create_button)

	var info_label: Label = Label.new()
	info_label.text = "%d programme(s) dans le catalogue du groupe" % programs.size()
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	actions.add_child(info_label)

	_build_table(dynamic, programs)


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _build_table(parent: VBoxContainer, programs: Array[Dictionary]) -> void:
	if programs.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Aucun programme dans le catalogue du groupe."
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
	_add_cell(table, "Épisodes", 3, true)
	_add_cell(table, "État", 4, true)

	for program: Dictionary in programs:
		_add_cell(table, String(program.get("name", "")), 0, false)
		_add_cell(table, String(program.get("format", "")), 1, false)
		_add_cell(table, "%d min" % int(program.get("duration_minutes", 0)), 2, false)
		_add_cell(table, _get_episode_text(program), 3, false)
		_add_cell(table, String(program.get("status", "Disponible")), 4, false)


static func _get_episode_text(program: Dictionary) -> String:
	var total: int = int(program.get("episodes_total", 0))
	var available: int = int(program.get("episodes_available", 0))
	if total <= 0:
		return "—"
	if available == total:
		return str(total)
	return "%d / %d disponibles" % [available, total]


static func _add_cell(table: GridContainer, text: String, column: int, is_header: bool) -> void:
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
	table.add_child(panel)

	var label: Label = Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_header:
		label.add_theme_font_size_override("font_size", 16)
	panel.add_child(label)
