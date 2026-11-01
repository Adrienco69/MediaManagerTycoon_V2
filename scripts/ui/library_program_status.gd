class_name LibraryProgramStatus
extends RefCounted


static func get_text(program: Dictionary) -> String:
	if not bool(program.get("owned_by_group", false)):
		return "Disponible"

	var status: String = String(program.get("status", "Disponible"))
	if status == "Production en cours":
		return "Disponible | Production en cours"

	# Le renouvellement est une action disponible depuis la fiche des
	# programmes appartenant au groupe du joueur.
	return "Disponible | Renouvellement"
