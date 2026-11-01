class_name LibraryProgramStatus
extends RefCounted


static func get_text(program: Dictionary) -> String:
	var status: String = String(program.get("status", "Disponible"))
	if status == "Production en cours":
		return "Disponible | Production en cours"

	var total: int = int(program.get("episodes_total", 0))
	var available: int = int(program.get("episodes_available", 0))
	if total > 0 and available > 0 and available < total:
		return "Disponible | Renouvellement"

	return "Disponible"
