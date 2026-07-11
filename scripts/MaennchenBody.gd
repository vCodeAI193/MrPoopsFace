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
	var is_sleeping: bool = _maennchen.sleeping
	var is_bomb: bool = _maennchen.is_bomb

	# Beinwinkel: beim Schlafen still, sonst animiert
	var swing: float = 0.0
	if not is_sleeping:
		swing = sin(_maennchen._walk_phase) * 12.0 * s

	# --- Kopf ---
	var head_center: Vector2 = Vector2(0, -70 * s)
	draw_arc(head_center, 22 * s, 0, TAU, 24, col, w)

	# --- Körper (Wirbelsäule) ---
	var neck: Vector2 = Vector2(0, -48 * s)
	var hip: Vector2 = Vector2(0, 10 * s)
	draw_line(neck, hip, col, w)

	# --- Arme (schlafend: hängen locker herunter) ---
	if is_sleeping:
		draw_line(neck, Vector2(-20 * s, 20 * s), col, w)
		draw_line(neck, Vector2(20 * s, 20 * s), col, w)
	else:
		draw_line(neck, Vector2(-28 * s, -20 * s), col, w)
		draw_line(neck, Vector2(28 * s, -20 * s), col, w)

	# --- Beine (laufen leicht) ---
	draw_line(hip, Vector2(-18 * s + swing, 55 * s), col, w)
	draw_line(hip, Vector2(18 * s - swing, 55 * s), col, w)

	# --- Regenschirm über dem Kopf (F026) ---
	if _maennchen.has_umbrella:
		var umb_col: Color = Color(0.85, 0.25, 0.3)
		var umb_top: Vector2 = Vector2(0, -125 * s)
		# Schirmdach als gefüllter Halbkreis
		_draw_half_disc(umb_top, 42 * s, umb_col)
		# Schirmstiel vom Dach zur Hand
		draw_line(umb_top, Vector2(0, -95 * s), Color(0.35, 0.25, 0.2), w * 0.6)

	# --- Schild-Anzeige (F023) ---
	if _maennchen.has_shield:
		# Schild-Balkens unter dem Kopf
		var shield_health: float = float(_maennchen._shield_hits) / 2.0
		draw_rect(Rect2(-25 * s, -45 * s, 50 * s, 6 * s), Color(0.2, 0.2, 0.2, 0.6))
		draw_rect(Rect2(-25 * s, -45 * s, 50 * s * shield_health, 6 * s),
			Color(0.8, 0.6, 0.1, 1.0))

	# --- Gesicht (offen oder schlafend/geschlossen/Bombe) ---
	if is_bomb:
		# Bomben-Männchen: rotes Ausrufezeichen statt normaler Augen (F029)
		var red: Color = Color(1.0, 0.1, 0.1, 0.9)
		draw_line(head_center + Vector2(0, -10 * s), head_center + Vector2(0, 5 * s), red, w * 0.85)
		draw_circle(head_center + Vector2(0, 11 * s), 3.5 * s, red)
	elif is_sleeping:
		# Geschlossene Augen als horizontale Striche
		draw_line(head_center + Vector2(-11 * s, -2 * s), head_center + Vector2(-3 * s, -2 * s), col, w * 0.65)
		draw_line(head_center + Vector2(3 * s, -2 * s), head_center + Vector2(11 * s, -2 * s), col, w * 0.65)
	else:
		draw_circle(head_center + Vector2(-7 * s, -3 * s), 3 * s, col)
		draw_circle(head_center + Vector2(7 * s, -3 * s), 3 * s, col)


## Zeichnet einen gefüllten, nach oben gewölbten Halbkreis (Schirmdach, F026).
func _draw_half_disc(center: Vector2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	const SEGMENTS: int = 16
	for i in SEGMENTS + 1:
		var angle: float = PI + PI * float(i) / SEGMENTS
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
