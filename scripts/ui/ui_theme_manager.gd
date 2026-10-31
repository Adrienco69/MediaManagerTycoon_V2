class_name UIThemeManager
extends RefCounted

const CalendarThemeScript = preload("res://scripts/calendar_theme.gd")
const TEXT_WHITE: Color = Color(1.0, 1.0, 1.0, 1.0)
const TEXT_WHITE_SOFT: Color = Color(1.0, 1.0, 1.0, 0.72)
const TEXT_WHITE_DISABLED: Color = Color(1.0, 1.0, 1.0, 0.45)


static func apply_calendar_theme(
	root: Control,
	background: ColorRect,
	white_labels: Array[Label],
	month_index: int,
	day_of_month: int,
	weeks_in_month: int
) -> void:
	var palette: Dictionary = CalendarThemeScript.get_palette(month_index, day_of_month, weeks_in_month)
	var background_color: Color = palette["background"]
	var surface_color: Color = palette["surface"]
	var surface_alt_color: Color = palette["surface_alt"]
	var accent_color: Color = palette["accent"]
	var accent_soft_color: Color = palette["accent_soft"]

	background.color = background_color
	root.theme = _build_theme(surface_color, surface_alt_color, accent_color, accent_soft_color)

	for label: Label in white_labels:
		label.add_theme_color_override("font_color", TEXT_WHITE)


static func _build_theme(
	surface: Color,
	surface_alt: Color,
	accent: Color,
	accent_soft: Color
) -> Theme:
	var result: Theme = Theme.new()

	# Les mois changent les surfaces et les bordures, jamais la couleur du texte.
	result.set_color("font_color", "Label", TEXT_WHITE)
	result.set_color("font_color", "Button", TEXT_WHITE)
	result.set_color("font_hover_color", "Button", TEXT_WHITE)
	result.set_color("font_pressed_color", "Button", TEXT_WHITE)
	result.set_color("font_disabled_color", "Button", TEXT_WHITE_DISABLED)
	result.set_color("font_color", "LineEdit", TEXT_WHITE)
	result.set_color("font_placeholder_color", "LineEdit", TEXT_WHITE_SOFT)
	result.set_color("caret_color", "LineEdit", TEXT_WHITE)

	result.set_stylebox("panel", "PanelContainer", _make_box(surface, accent.darkened(0.45), 10, 1))
	result.set_stylebox("normal", "Button", _make_box(surface_alt, accent.darkened(0.35), 8, 1))
	result.set_stylebox("hover", "Button", _make_box(surface_alt.lightened(0.10), accent, 8, 1))
	result.set_stylebox("pressed", "Button", _make_box(accent.darkened(0.35), accent_soft, 8, 1))
	result.set_stylebox("disabled", "Button", _make_box(surface.darkened(0.10), surface_alt, 8, 1))
	result.set_stylebox("focus", "Button", _make_outline_box(accent_soft, 8, 2))
	result.set_stylebox("normal", "LineEdit", _make_box(surface_alt.darkened(0.08), accent.darkened(0.30), 8, 1))
	result.set_stylebox("focus", "LineEdit", _make_box(surface_alt, accent_soft, 8, 2))
	result.set_stylebox("separator", "HSeparator", _make_separator_box(accent.darkened(0.20)))
	return result


static func _make_box(background_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
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


static func _make_outline_box(border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
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


static func _make_separator_box(separator_color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = separator_color
	box.content_margin_top = 1.0
	box.content_margin_bottom = 1.0
	return box
