class_name StartMenuController
extends RefCounted


static func show_home(
	home_panel: Control,
	new_game_panel: Control,
	load_button: Button,
	start_error_label: Label,
	has_save: bool
) -> void:
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
	home_panel.visible = false
	new_game_panel.visible = true
	start_error_label.text = ""
	player_name_input.grab_focus()


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
