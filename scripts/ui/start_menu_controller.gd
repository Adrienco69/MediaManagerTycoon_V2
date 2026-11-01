class_name StartMenuController
extends RefCounted


static func show_home(
	home_panel: Control,
	new_game_panel: Control,
	load_button: Button,
	start_error_label: Label
) -> void:
	home_panel.visible = true
	new_game_panel.visible = false
	start_error_label.text = ""
	load_button.disabled = true
	load_button.tooltip_text = "Le chargement sera disponible dès que le système de sauvegarde sera branché."


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
