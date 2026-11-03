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

	_apply_option_button_theme(result, surface, surface_alt, accent, accent_soft)
	_apply_popup_menu_theme(result, surface, surface_alt, accent, accent_soft)
	_apply_item_list_theme(result, surface, surface_alt, accent, accent_soft)
	_apply_scrollbar_theme(result, surface, surface_alt, accent, accent_soft)
	_apply_window_theme(result, surface, surface_alt, accent, accent_soft)
	return result


# Applique le thème courant même aux fenêtres qui créent leur propre viewport.
static func apply_popup_theme(popup: Window, source: Node) -> void:
	var cursor: Node = source
	while cursor != null:
		if cursor is Control:
			var local_theme: Theme = (cursor as Control).theme
			if local_theme != null:
				popup.theme = local_theme
				return
		elif cursor is Window:
			var window_theme: Theme = (cursor as Window).theme
			if window_theme != null:
				popup.theme = window_theme
				return
		cursor = cursor.get_parent()


# Met en valeur le programme cible dans les confirmations de la grille.
static func configure_program_confirmation(
	dialog: ConfirmationDialog,
	prompt: String,
	program_name: String,
	note: String
) -> void:
	dialog.dialog_text = ""
	dialog.get_label().hide()

	var palette: Dictionary = CalendarThemeScript.get_palette(
		GameState.month_index,
		GameState.get_day_of_month(),
		int(GameState.MONTHS[GameState.month_index].get("weeks", 7))
	)
	var surface_alt: Color = palette["surface_alt"]
	var accent: Color = palette["accent"]
	var accent_soft: Color = palette["accent_soft"]

	var content: VBoxContainer = VBoxContainer.new()
	content.custom_minimum_size = Vector2(480, 0)
	content.add_theme_constant_override("separation", 12)
	dialog.get_vbox().add_child(content)
	dialog.get_vbox().move_child(content, 0)

	var question: Label = Label.new()
	question.text = prompt
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(question)

	var focus_panel: PanelContainer = PanelContainer.new()
	var focus_style: StyleBoxFlat = _make_box(
		surface_alt.lightened(0.12), accent_soft, 8, 1
	)
	focus_style.content_margin_top = 12
	focus_style.content_margin_bottom = 12
	focus_panel.add_theme_stylebox_override("panel", focus_style)
	content.add_child(focus_panel)

	var name_label: RichTextLabel = RichTextLabel.new()
	name_label.bbcode_enabled = true
	name_label.fit_content = true
	name_label.scroll_active = false
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.custom_minimum_size = Vector2(0, 30)
	name_label.add_theme_color_override("default_color", TEXT_WHITE)
	name_label.text = "[b]%s[/b]" % program_name.replace("[", "［").replace("]", "］")
	focus_panel.add_child(name_label)

	var description: Label = Label.new()
	description.text = note
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)


static func _apply_window_theme(
	theme: Theme,
	surface: Color,
	surface_alt: Color,
	accent: Color,
	accent_soft: Color
) -> void:
	var dialog_panel: StyleBoxFlat = _make_box(surface, accent, 10, 2)
	dialog_panel.content_margin_left = 18
	dialog_panel.content_margin_right = 18
	dialog_panel.content_margin_top = 16
	dialog_panel.content_margin_bottom = 16
	theme.set_stylebox("panel", "AcceptDialog", dialog_panel)
	theme.set_stylebox("panel", "ConfirmationDialog", dialog_panel)
	theme.set_stylebox("panel", "PopupPanel", _make_box(surface, accent, 10, 2))
	theme.set_constant("buttons_min_height", "AcceptDialog", 40)
	theme.set_constant("buttons_min_width", "AcceptDialog", 110)
	theme.set_constant("buttons_separation", "AcceptDialog", 14)
	theme.set_color("title_color", "Window", TEXT_WHITE)
	theme.set_stylebox("embedded_border", "Window", _make_box(surface, accent, 10, 2))
	theme.set_stylebox("embedded_unfocused_border", "Window", _make_box(surface, accent.darkened(0.25), 10, 1))
	theme.set_stylebox("panel", "Window", _make_box(surface_alt, accent, 10, 2))
	theme.set_constant("title_height", "Window", 36)


static func _apply_option_button_theme(
	theme: Theme,
	surface: Color,
	surface_alt: Color,
	accent: Color,
	accent_soft: Color
) -> void:
	theme.set_color("font_color", "OptionButton", TEXT_WHITE)
	theme.set_color("font_hover_color", "OptionButton", TEXT_WHITE)
	theme.set_color("font_pressed_color", "OptionButton", TEXT_WHITE)
	theme.set_color("font_focus_color", "OptionButton", TEXT_WHITE)
	theme.set_color("font_disabled_color", "OptionButton", TEXT_WHITE_DISABLED)

	theme.set_stylebox("normal", "OptionButton", _make_box(surface_alt, accent.darkened(0.35), 8, 1))
	theme.set_stylebox("hover", "OptionButton", _make_box(surface_alt.lightened(0.10), accent, 8, 1))
	theme.set_stylebox("pressed", "OptionButton", _make_box(accent.darkened(0.35), accent_soft, 8, 1))
	theme.set_stylebox("disabled", "OptionButton", _make_box(surface.darkened(0.10), surface_alt, 8, 1))
	theme.set_stylebox("focus", "OptionButton", _make_outline_box(accent_soft, 8, 2))


static func _apply_popup_menu_theme(
	theme: Theme,
	surface: Color,
	surface_alt: Color,
	accent: Color,
	accent_soft: Color
) -> void:
	theme.set_color("font_color", "PopupMenu", TEXT_WHITE)
	theme.set_color("font_hover_color", "PopupMenu", TEXT_WHITE)
	theme.set_color("font_accelerator_color", "PopupMenu", TEXT_WHITE_SOFT)
	theme.set_color("font_disabled_color", "PopupMenu", TEXT_WHITE_DISABLED)
	theme.set_color("font_separator_color", "PopupMenu", TEXT_WHITE_SOFT)

	theme.set_stylebox("panel", "PopupMenu", _make_box(surface, accent.darkened(0.25), 8, 1))
	theme.set_stylebox("hover", "PopupMenu", _make_box(surface_alt.lightened(0.10), accent, 5, 1))
	theme.set_stylebox("separator", "PopupMenu", _make_separator_box(accent.darkened(0.20)))
	theme.set_stylebox("labeled_separator_left", "PopupMenu", _make_separator_box(accent.darkened(0.20)))
	theme.set_stylebox("labeled_separator_right", "PopupMenu", _make_separator_box(accent.darkened(0.20)))

	# Garde une marge lisible autour des éléments du menu ouvert.
	theme.set_constant("item_start_padding", "PopupMenu", 10)
	theme.set_constant("item_end_padding", "PopupMenu", 10)
	theme.set_constant("outline_size", "PopupMenu", 0)


static func _apply_item_list_theme(
	theme: Theme,
	surface: Color,
	surface_alt: Color,
	accent: Color,
	accent_soft: Color
) -> void:
	theme.set_color("font_color", "ItemList", TEXT_WHITE)
	theme.set_color("font_hovered_color", "ItemList", TEXT_WHITE)
	theme.set_color("font_selected_color", "ItemList", TEXT_WHITE)
	theme.set_color("guide_color", "ItemList", accent.darkened(0.30))

	# Évite totalement le rendu gris/noir natif de Godot.
	theme.set_stylebox("panel", "ItemList", _make_box(surface, accent.darkened(0.35), 8, 1))
	theme.set_stylebox("focus", "ItemList", _make_outline_box(accent_soft, 8, 2))
	theme.set_stylebox("selected", "ItemList", _make_box(accent.darkened(0.35), accent, 6, 1))
	theme.set_stylebox("selected_focus", "ItemList", _make_box(accent.darkened(0.30), accent_soft, 6, 2))
	theme.set_stylebox("cursor", "ItemList", _make_outline_box(accent, 6, 1))
	theme.set_stylebox("cursor_unfocused", "ItemList", _make_outline_box(accent.darkened(0.25), 6, 1))

	theme.set_constant("h_separation", "ItemList", 6)
	theme.set_constant("v_separation", "ItemList", 4)
	theme.set_constant("icon_margin", "ItemList", 8)
	theme.set_constant("line_separation", "ItemList", 4)


static func _apply_scrollbar_theme(
	theme: Theme,
	surface: Color,
	surface_alt: Color,
	accent: Color,
	accent_soft: Color
) -> void:
	for type_name: String in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", type_name, _make_box(surface.darkened(0.08), surface, 8, 0))
		theme.set_stylebox("grabber", type_name, _make_box(surface_alt, accent.darkened(0.20), 8, 1))
		theme.set_stylebox("grabber_highlight", type_name, _make_box(surface_alt.lightened(0.10), accent, 8, 1))
		theme.set_stylebox("grabber_pressed", type_name, _make_box(accent.darkened(0.25), accent_soft, 8, 1))


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
