extends Node2D
## MaennchenBody – zeichnet das eigentliche Strichmännchen.
## Liegt als Kind unter dem Maennchen-Area2D, damit es beim Treffer
## unabhängig vom Kollisionsbereich gedreht und animiert werden kann.
## Gezeichnet aus einfachen Linien (entspricht optisch einem Line2D-Strichmännchen).

@onready var _maennchen = get_parent()


func _draw() -> void:
	var col: Color = _maennchen.figure_color
	var s: float = _maennchen.figure_scale
	var w: float = 6.0 * s                       # Strichstärke

	# Animierter Beinwinkel beim Laufen
	var swing: float = sin(_maennchen._walk_phase) * 12.0 * s

	# --- Kopf ---
	var head_center: Vector2 = Vector2(0, -70 * s)
	draw_arc(head_center, 22 * s, 0, TAU, 24, col, w)

	# --- Körper (Wirbelsäule) ---
	var neck: Vector2 = Vector2(0, -48 * s)
	var hip: Vector2 = Vector2(0, 10 * s)
	draw_line(neck, hip, col, w)

	# --- Arme ---
	draw_line(neck, Vector2(-28 * s, -20 * s), col, w)
	draw_line(neck, Vector2(28 * s, -20 * s), col, w)

	# --- Beine (laufen leicht) ---
	draw_line(hip, Vector2(-18 * s + swing, 55 * s), col, w)
	draw_line(hip, Vector2(18 * s - swing, 55 * s), col, w)

	# --- Gesicht (zwei kleine Augen) ---
	draw_circle(head_center + Vector2(-7 * s, -3 * s), 3 * s, col)
	draw_circle(head_center + Vector2(7 * s, -3 * s), 3 * s, col)
