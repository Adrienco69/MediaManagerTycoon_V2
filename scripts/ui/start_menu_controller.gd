class_name StartMenuController
extends RefCounted

const HOME_LAYOUT_NAME: String = "HomeLayout"
const HOME_LOGO_PATH: String = "Margin/VBox/HomeLogo"


static func show_home(
	home_panel: Control,
	new_game_panel: Control,
	load_button: Button,
	start_error_label: Label,
	has_save: bool
) -> void:
	var home_layout: Control = _ensure_home_layout(home_panel)
	home_layout.visible = true
	home_panel.visible = true
	new_game_panel.visible = false
	start_error_label.text = ""
	load_button.disabled = not has_save
	if has_save:
		load_button.tooltip_text = "Charger la sauvegarde principale."
	else:
		load_button.tooltip_text = "Aucune sauvegarde disponible."


static func show_new_game(
	home_panel: Control,
	new_game_panel: Control,
	player_name_input: LineEdit,
	start_error_label: Label
) -> void:
	var home_layout: Control = _ensure_home_layout(home_panel)
	home_layout.visible = false
	home_panel.visible = false
	new_game_panel.visible = true
	start_error_label.text = ""
	player_name_input.grab_focus()


static func ensure_continue_button(home_panel: Control, on_continue: Callable) -> Button:
	var vbox: VBoxContainer = home_panel.get_node("Margin/VBox") as VBoxContainer
	var existing: Button = vbox.get_node_or_null("ContinueGameButton") as Button
	if existing != null:
		return existing

	var continue_button: Button = Button.new()
	continue_button.name = "ContinueGameButton"
	continue_button.text = "Continuer"
	continue_button.custom_minimum_size = Vector2(0, 52)
	continue_button.visible = false
	continue_button.pressed.connect(on_continue)
	vbox.add_child(continue_button)

	var new_game_button: Button = vbox.get_node_or_null("NewGameMenuButton") as Button
	if new_game_button != null:
		vbox.move_child(continue_button, new_game_button.get_index())

	return continue_button


static func ensure_quit_button(home_panel: Control, on_quit: Callable) -> Button:
	var vbox: VBoxContainer = home_panel.get_node("Margin/VBox") as VBoxContainer
	var existing: Button = vbox.get_node_or_null("QuitGameButton") as Button
	if existing != null:
		return existing

	var quit_button: Button = Button.new()
	quit_button.name = "QuitGameButton"
	quit_button.text = "Quitter"
	quit_button.custom_minimum_size = Vector2(0, 52)
	quit_button.pressed.connect(on_quit)
	vbox.add_child(quit_button)
	return quit_button


static func _ensure_home_layout(home_panel: Control) -> Control:
	var current_parent: Node = home_panel.get_parent()
	if current_parent is VBoxContainer and current_parent.name == HOME_LAYOUT_NAME:
		return current_parent as Control

	var center: Control = current_parent as Control
	var logo: TextureRect = home_panel.get_node_or_null(HOME_LOGO_PATH) as TextureRect
	if center == null or logo == null:
		return home_panel

	var original_index: int = home_panel.get_index()
	var home_layout: VBoxContainer = VBoxContainer.new()
	home_layout.name = HOME_LAYOUT_NAME
	home_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	home_layout.add_theme_constant_override("separation", 8)
	center.add_child(home_layout)
	center.move_child(home_layout, original_index)

	logo.reparent(home_layout)
	home_panel.reparent(home_layout)
	home_layout.move_child(logo, 0)
	home_layout.move_child(home_panel, 1)

	logo.custom_minimum_size = Vector2(320, 260)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	return home_layout
