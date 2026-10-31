class_name CalendarTheme
extends RefCounted

# Identité visuelle des 7 mois de Media Manager Tycoon.
# Les couleurs sont interpolées au fil des jours afin d'éviter un changement brutal
# lors du passage d'un mois au suivant.
const PALETTES := [
	{
		"name": "Floréal",
		"background": Color("#142019"),
		"surface": Color("#223126"),
		"surface_alt": Color("#2d4233"),
		"accent": Color("#78bd72"),
		"accent_soft": Color("#acd69d"),
		"text": Color("#f2f7f2"),
		"muted": Color("#b7c7b9")
	},
	{
		"name": "Clôture",
		"background": Color("#211c12"),
		"surface": Color("#352c1b"),
		"surface_alt": Color("#493b23"),
		"accent": Color("#d6a84f"),
		"accent_soft": Color("#efd08a"),
		"text": Color("#fff8e8"),
		"muted": Color("#d3c7a9")
	},
	{
		"name": "Crépuscule",
		"background": Color("#211826"),
		"surface": Color("#34233b"),
		"surface_alt": Color("#47304e"),
		"accent": Color("#b276c7"),
		"accent_soft": Color("#d9a6e5"),
		"text": Color("#fbf2ff"),
		"muted": Color("#cdb9d3")
	},
	{
		"name": "Zénith",
		"background": Color("#13202a"),
		"surface": Color("#203746"),
		"surface_alt": Color("#2b4c5f"),
		"accent": Color("#55b9d7"),
		"accent_soft": Color("#91d9ea"),
		"text": Color("#eefaff"),
		"muted": Color("#b3ccd5")
	},
	{
		"name": "Origine",
		"background": Color("#221713"),
		"surface": Color("#37241d"),
		"surface_alt": Color("#4b3025"),
		"accent": Color("#ca7959"),
		"accent_soft": Color("#e9aa8c"),
		"text": Color("#fff4ef"),
		"muted": Color("#d6beb3")
	},
	{
		"name": "Essor",
		"background": Color("#102120"),
		"surface": Color("#193735"),
		"surface_alt": Color("#234b48"),
		"accent": Color("#4fb9aa"),
		"accent_soft": Color("#8bd9cd"),
		"text": Color("#effbf9"),
		"muted": Color("#b0d0cb")
	},
	{
		"name": "Brumal",
		"background": Color("#171b2c"),
		"surface": Color("#252b43"),
		"surface_alt": Color("#333b59"),
		"accent": Color("#7e91d5"),
		"accent_soft": Color("#aebcea"),
		"text": Color("#f3f5ff"),
		"muted": Color("#bec4db")
	}
]


static func get_palette(month_index: int, day_of_month: int, weeks_in_month: int) -> Dictionary:
	var safe_index := posmod(month_index, PALETTES.size())
	var next_index := (safe_index + 1) % PALETTES.size()
	var current: Dictionary = PALETTES[safe_index]
	var next: Dictionary = PALETTES[next_index]
	var total_days := max(weeks_in_month * 7, 1)
	var raw_progress := clamp(float(day_of_month - 1) / float(max(total_days - 1, 1)), 0.0, 1.0)
	# Smoothstep : la transition reste douce au début et à la fin du mois.
	var progress := raw_progress * raw_progress * (3.0 - (2.0 * raw_progress))

	return {
		"name": current["name"],
		"background": (current["background"] as Color).lerp(next["background"] as Color, progress),
		"surface": (current["surface"] as Color).lerp(next["surface"] as Color, progress),
		"surface_alt": (current["surface_alt"] as Color).lerp(next["surface_alt"] as Color, progress),
		"accent": (current["accent"] as Color).lerp(next["accent"] as Color, progress),
		"accent_soft": (current["accent_soft"] as Color).lerp(next["accent_soft"] as Color, progress),
		"text": (current["text"] as Color).lerp(next["text"] as Color, progress),
		"muted": (current["muted"] as Color).lerp(next["muted"] as Color, progress)
	}
