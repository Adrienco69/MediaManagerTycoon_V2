class_name ProductionTableBuilder
extends RefCounted

const ProductionRulesScript = preload("res://scripts/core/production_rules.gd")
const COLUMN_WIDTHS: Array[float] = [280.0, 170.0, 100.0, 180.0, 180.0, 280.0]


static func build(parent: VBoxContainer, productions: Array[Dictionary]) -> void:
	if productions.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Aucune production en cours."
		parent.add_child(empty_label)
		return

	var table: GridContainer = GridContainer.new()
	table.columns = 6
	table.add_theme_constant_override("h_separation", 0)
	table.add_theme_constant_override("v_separation", 0)
	parent.add_child(table)

	_add_cell(table, "Programme", 0, true)
	_add_cell(table, "Format", 1, true)
	_add_cell(table, "Slot", 2, true)
	_add_cell(table, "Lot", 3, true)
	_add_cell(table, "Temps restant", 4, true)
	_add_cell(table, "État", 5, true)

	for production: Dictionary in productions:
		var total_units: int = ProductionRulesScript.get_unit_count(production)
		var remaining_minutes: int = int(production.get("production_remaining_minutes", 0))
		var slot_index: int = int(production.get("slot_index", 0))

		_add_cell(table, String(production.get("name", "")), 0, false)
		_add_cell(table, String(production.get("format", "")), 1, false)
		_add_cell(table, "Slot %d" % slot_index if slot_index > 0 else "Slot ?", 2, false)
		_add_cell(table, "%d unité(s)" % total_units, 3, false)
		_add_cell(table, ProductionRulesScript.format_remaining_time(remaining_minutes), 4, false)
		_add_cell(table, "Lot en production | non diffusable", 5, false)


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
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if is_header:
		label.add_theme_font_size_override("font_size", 16)
	panel.add_child(label)
