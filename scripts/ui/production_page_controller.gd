class_name ProductionPageController
extends RefCounted

const DYNAMIC_NODE_NAME: String = "ProductionDynamic"
const COLUMN_WIDTHS: Array[float] = [320.0, 190.0, 170.0, 220.0]


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	active_productions: Array[Dictionary],
	on_create_production: Callable
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Créez de nouvelles productions et suivez uniquement celles qui sont en cours."

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.add_theme_constant_override("separation", 12)
	content_container.add_child(dynamic)

	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	dynamic.add_child(actions)

	var create_button: Button = Button.new()
	create_button.text = "Créer une production"
	create_button.custom_minimum_size = Vector2(190, 42)
	create_button.pressed.connect(on_create_production)
	actions.add_child(create_button)

	var info_label: Label = Label.new()
	info_label.text = "%d production(s) en cours" % active_productions.size()
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	actions.add_child(info_label)

	_build_table(dynamic, active_productions)


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _build_table(parent: VBoxContainer, productions: Array[Dictionary]) -> void:
	if productions.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Aucune production en cours."
		parent.add_child(empty_label)
		return

	var table: GridContainer = GridContainer.new()
	table.columns = 4
	table.add_theme_constant_override("h_separation", 0)
	table.add_theme_constant_override("v_separation", 0)
	parent.add_child(table)

	_add_cell(table, "Programme", 0, true)
	_add_cell(table, "Format", 1, true)
	_add_cell(table, "En production", 2, true)
	_add_cell(table, "État", 3, true)

	for program: Dictionary in productions:
		_add_cell(table, String(program.get("name", "")), 0, false)
		_add_cell(table, String(program.get("format", "")), 1, false)
		_add_cell(table, _get_current_production_text(program), 2, false)
		_add_cell(table, String(program.get("status", "Production en cours")), 3, false)


static func _get_current_production_text(program: Dictionary) -> String:
	var current_episode: int = int(program.get("current_episode", 0))
	if current_episode > 0:
		return "Épisode %d" % current_episode
	return "Production en cours"


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
