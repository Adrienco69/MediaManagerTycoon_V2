class_name DailyBroadcastReport
extends RefCounted

const UIThemeManagerScript = preload("res://scripts/ui/ui_theme_manager.gd")
const MINUTES_PER_DAY: int = 1440
const DAYS_PER_YEAR: int = 364

# Fenêtre de consultation volontaire : aucune pause ni interruption quotidienne.
static func open(anchor: Control) -> void:
	var popup: PopupPanel = PopupPanel.new()
	popup.name = "DailyBroadcastReport"
	popup.title = "Bilan des diffusions"
	anchor.add_child(popup)
	UIThemeManagerScript.apply_popup_theme(popup, anchor)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	popup.add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.custom_minimum_size = Vector2(665, 420)
	root.add_theme_constant_override("separation", 11)
	margin.add_child(root)

	var title: Label = Label.new()
	title.text = "Bilan quotidien des diffusions"
	title.add_theme_font_size_override("font_size", 21)
	root.add_child(title)

	var selectors: HBoxContainer = HBoxContainer.new()
	selectors.add_theme_constant_override("separation", 10)
	root.add_child(selectors)

	var today_button: Button = Button.new()
	today_button.text = "Aujourd'hui"
	selectors.add_child(today_button)

	var yesterday_button: Button = Button.new()
	yesterday_button.text = "Hier"
	selectors.add_child(yesterday_button)

	var date_label: Label = Label.new()
	date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selectors.add_child(date_label)

	var summary: Label = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(summary)

	var scroller: ScrollContainer = ScrollContainer.new()
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.custom_minimum_size = Vector2(0, 265)
	root.add_child(scroller)

	var detail: VBoxContainer = VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 8)
	scroller.add_child(detail)

	var close_row: HBoxContainer = HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(close_row)
	var close_button: Button = Button.new()
	close_button.text = "Fermer"
	close_button.custom_minimum_size = Vector2(120, 36)
	close_row.add_child(close_button)
	close_button.pressed.connect(popup.hide)

	var current_day: int = (GameState.week_in_year - 1) * 7 + GameState.day_in_week - 1
	var current_absolute: int = (GameState.year - 1) * DAYS_PER_YEAR + current_day

	today_button.pressed.connect(func() -> void:
		_render(current_absolute, date_label, summary, detail)
	)
	yesterday_button.pressed.connect(func() -> void:
		_render(current_absolute - 1, date_label, summary, detail)
	)
	popup.popup_hide.connect(func() -> void:
		popup.queue_free()
	)

	_render(current_absolute - 1, date_label, summary, detail)
	popup.popup_centered(Vector2i(710, 540))


static func _render(
	absolute_day: int,
	date_label: Label,
	summary: Label,
	detail: VBoxContainer
) -> void:
	for old_child: Node in detail.get_children():
		detail.remove_child(old_child)
		old_child.queue_free()

	if absolute_day < 0:
		date_label.text = "Avant le début de la partie"
		summary.text = "Aucune diffusion enregistrée."
		return

	var year_number: int = int(absolute_day / DAYS_PER_YEAR) + 1
	var day_number: int = absolute_day % DAYS_PER_YEAR
	var days: Array[String] = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
	date_label.text = "%s | Année %d, semaine %d" % [
		days[day_number % 7], year_number, int(day_number / 7) + 1
	]

	var entries: Array[Dictionary] = []
	var total_cc: int = 0
	var total_viewers: int = 0
	for event: Dictionary in GameState.get_broadcast_results():
		if int(event.get("year", -1)) != year_number:
			continue
		if int(event.get("day_of_year", -1)) != day_number:
			continue
		entries.append(event)
		total_cc += int(event.get("revenue_cc", 0))
		total_viewers += int(event.get("audience_viewers", 0))

	summary.text = "%d diffusion(s) | +%d CC | %d téléspectateurs cumulés*" % [
		entries.size(), total_cc, total_viewers
	]
	if entries.is_empty():
		var empty: Label = Label.new()
		empty.text = "Aucune diffusion effectuée ce jour."
		detail.add_child(empty)
		return

	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("slot", 0)) < int(b.get("slot", 0))
	)
	for event: Dictionary in entries:
		var label: Label = Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var episode: int = int(event.get("episode_global", 0))
		var episode_suffix: String = " | Épisode %d" % episode if episode > 0 else ""
		label.text = "%s | %s%s | %s | %d spectateurs | +%d CC" % [
			String(event.get("time", "")),
			String(event.get("program_name", "Programme")),
			episode_suffix,
			String(event.get("type", "Diffusion")),
			int(event.get("audience_viewers", 0)),
			int(event.get("revenue_cc", 0))
		]
		detail.add_child(label)

	var note: Label = Label.new()
	note.text = "* Somme des audiences des passages, pas des téléspectateurs uniques."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(note)
