class_name LaunchProgramCatalog
extends RefCounted

const TELEFILMS: Array[String] = [
	"Un jour presque ordinaire",
	"Tout devait bien se passer",
	"Le monde d’après nous"
]


static func build(channel_name: String, player_series_telefilm: Dictionary) -> Array[Dictionary]:
	var programs: Array[Dictionary] = []

	programs.append(_program("Notre monde en crises", "Shortcom", 30, 25, 25))
	programs.append(_program("Le futur pour un passée", "Shortcom", 30, 50, 50))

	# Tous les épisodes de lancement sont déjà possédés par le groupe.
	# La limite des inédits chaîne relève uniquement de la programmation.
	programs.append(_seasoned_program(
		"La vie du lycée",
		"Série",
		90,
		7,
		11
	))
	programs.append(_program("Une famille presque parfaite", "Série", 60, 21, 21))

	if not player_series_telefilm.is_empty():
		var series_telefilm_name: String = String(player_series_telefilm.get("name", ""))
		var series_telefilm_episodes: int = int(player_series_telefilm.get("episodes", 0))
		if not series_telefilm_name.is_empty() and series_telefilm_episodes > 0:
			programs.append(_program(
				series_telefilm_name,
				"Série-téléfilm",
				90,
				series_telefilm_episodes,
				series_telefilm_episodes
			))

	programs.append(_program("Combien j’ai de CC", "Jeux TV", 30, 15, 15))
	programs.append(_program("Le bon prix", "Jeux TV", 90, 5, 5))
	programs.append(_program("Tout le monde avec…", "Documentaire", 120, 5, 5))
	programs.append(_program("Dans les coulisses de %s" % channel_name, "Documentaire", 90, 5, 5))
	programs.append(_program("Ce soir, c’est nous !", "Divertissement", 150, 10, 10))
	programs.append(_program("Retour vers nos souvenirs", "Divertissement", 150, 10, 10))
	programs.append(_program("Ça nous concerne", "Magazine", 60, 35, 35))
	programs.append(_program("Mode d’emploi", "Magazine", 60, 35, 35))
	programs.append(_program("La vie des folles", "Télé-réalité", 60, 21, 21))
	programs.append(_program("Les Ailescapés de la réalité", "Télé-réalité", 30, 50, 50))
	programs.append(_program("@Talk", "Talk-show", 120, 0, 0))

	var telefilm_index: int = randi_range(0, TELEFILMS.size() - 1)
	programs.append(_program(TELEFILMS[telefilm_index], "Téléfilm", 150, 1, 1))
	return programs


static func _seasoned_program(
	name: String,
	format_name: String,
	duration_minutes: int,
	season_count: int,
	episodes_per_season: int
) -> Dictionary:
	var total_episodes: int = season_count * episodes_per_season
	var program: Dictionary = _program(
		name,
		format_name,
		duration_minutes,
		total_episodes,
		total_episodes
	)
	program["season_count"] = season_count
	program["seasons"] = _build_equal_seasons(season_count, episodes_per_season)
	return program


static func _build_equal_seasons(season_count: int, episodes_per_season: int) -> Array[Dictionary]:
	var seasons: Array[Dictionary] = []
	for season_number: int in range(1, season_count + 1):
		var first_episode: int = ((season_number - 1) * episodes_per_season) + 1
		var last_episode: int = first_episode + episodes_per_season - 1
		seasons.append({
			"number": season_number,
			"episode_count": episodes_per_season,
			"first_episode": first_episode,
			"last_episode": last_episode
		})
	return seasons


static func _program(
	name: String,
	format_name: String,
	duration_minutes: int,
	episodes_total: int,
	episodes_available: int,
	status: String = "Disponible",
	current_episode: int = 0
) -> Dictionary:
	return {
		"id": name.to_lower().replace(" ", "_").replace("’", "").replace("'", ""),
		"name": name,
		"format": format_name,
		"duration_minutes": duration_minutes,
		"episodes_total": episodes_total,
		"episodes_available": episodes_available,
		"status": status,
		"current_episode": current_episode,
		"season_count": 0,
		"seasons": [],
		"broadcast_history": [],
		"source": "launch",
		"owned_by_group": true
	}
