extends Node
## GameManager (Autoload)
## Verwaltet den globalen Spielzustand: Punktestand, Combo und Rundentimer.
## Wird in der Projektkonfiguration als Singleton "GameManager" registriert.

# --- Signale, über die sich die HUD und andere Knoten benachrichtigen lassen ---
signal score_changed(new_score: int)          ## Wird bei Punkteänderung gesendet
signal combo_changed(new_combo: int)           ## Wird bei Combo-Änderung gesendet
signal streak_changed(new_streak: int)         ## Wird bei Streak-Änderung gesendet (F126)
signal time_changed(seconds_left: float)       ## Wird jede Sekunde aktualisiert
signal game_over(final_score: int)             ## Wird beim Rundenende gesendet
signal game_started()                          ## Wird beim Rundenstart gesendet
signal hit_registered(points: int)             ## Wird bei jedem Treffer gesendet (für Effekte)

# --- Einstellbare Werte (im Inspector / per Code anpassbar) ---
@export var round_duration: float = 60.0       ## Rundenlänge in Sekunden
@export var combo_time_window: float = 1.5     ## Zeitfenster für aufeinanderfolgende Treffer
@export var base_hit_points: int = 10          ## Grundpunkte pro Treffer

# --- Spielmodi & Schwierigkeit (F085, F089) ---
var game_mode: String = "normal"               ## "normal", "practice", "easy", "hard" (F085, F089)
enum Difficulty {EASY, NORMAL, HARD}
var difficulty: int = Difficulty.NORMAL

# --- Laufzeit-Status ---
var score: int = 0
var combo: int = 0
var streak: int = 0                           ## Aktuelle Treffer-Streak (F126)
var time_left: float = 0.0
var game_active: bool = false

# --- Persistenz / Highscores (F168, F195) ---
const SAVE_PATH: String = "user://stinky_toss.save"
const MAX_HIGHSCORES: int = 10
var highscores: Array = []                     ## Top-Punktestände (absteigend)
var last_was_highscore: bool = false           ## Letzte Runde war neuer Rekord?

# --- Spielstatistiken (F130) ---
var best_combo: int = 0               ## Beste Combo in dieser Runde
var hits_total: int = 0               ## Gesamtzahl Treffer
var avg_points_per_hit: float = 0.0   ## Durchschnitt Punkte/Treffer

var _combo_timer: float = 0.0                  ## Restzeit, in der die Combo gültig bleibt
var combo_timer_pct: float = 0.0              ## Verhältnis 0..1 für den Fortschrittsbalken (F119)
var combo_shield_active: bool = false         ## Läuft der Combo-Schutz gerade? (F049)
var _combo_shield_timer: float = 0.0

# --- Power-Up System (F041/F042/F043/F044/F052) ---
var active_powerups: Dictionary = {}          ## Aktive Power-Ups: {"type": {duration: float, data: {...}}}
var projectile_scale_bonus: float = 1.0       ## Geschoss-Größen-Multiplikator (F044)
var points_multiplier: float = 1.0             ## Punkte-Multiplikator (F042)
var multi_shot_count: int = 1                 ## Anzahl Geschosse pro Wurf (F043)

# --- Game Modes & Einstellungen ---
var game_mode: String = "normal"               ## "normal", "practice" (F085), "hard" (F089)
var difficulty: String = "medium"              ## "easy", "medium", "hard" (F089)


func _ready() -> void:
	_load_game()


func _process(delta: float) -> void:
	if not game_active:
		return

	# Rundentimer herunterzählen
	time_left -= delta
	time_changed.emit(time_left)

	# Combo-Schutz herunterzählen (F049)
	if combo_shield_active:
		_combo_shield_timer -= delta
		if _combo_shield_timer <= 0.0:
			combo_shield_active = false

	# Combo-Fenster herunterzählen; während Combo-Schutz aktiv bleibt es eingefroren
	if _combo_timer > 0.0 and not combo_shield_active:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_reset_combo()
	combo_timer_pct = clampf(_combo_timer / combo_time_window, 0.0, 1.0) if combo > 0 else 0.0

	# Power-Ups aktualisieren (F041/F044/F052)
	var expired_powerups: Array = []
	for key in active_powerups:
		var pu = active_powerups[key]
		pu["duration"] -= delta
		if pu["duration"] <= 0.0:
			expired_powerups.append(key)
	for key in expired_powerups:
		_deactivate_powerup(key)

	# Runde beenden, wenn die Zeit abgelaufen ist
	if time_left <= 0.0:
		time_left = 0.0
		end_game()


## Startet eine neue Runde und setzt alle Werte zurück.
func start_game() -> void:
	score = 0
	combo = 0
	streak = 0
	_combo_timer = 0.0
	# Übungsmodus (F085): extrem lange Zeit (praktisch unbegrenzt)
	time_left = round_duration if game_mode != "practice" else 3600.0
	game_active = true
	# Statistiken zurücksetzen (F130)
	best_combo = 0
	hits_total = 0
	avg_points_per_hit = 0.0
	score_changed.emit(score)
	combo_changed.emit(combo)
	streak_changed.emit(streak)
	time_changed.emit(time_left)
	game_started.emit()


## Beendet die laufende Runde und meldet den Endpunktestand.
func end_game() -> void:
	if not game_active:
		return
	game_active = false
	# Prüfen, ob es ein neuer Rekord ist, bevor der Score eingetragen wird
	last_was_highscore = score > 0 and (highscores.is_empty() or score > int(highscores[0]))
	_record_highscore(score)
	game_over.emit(score)


## Registriert einen Treffer auf ein Strichmännchen und berechnet die Punkte
## inklusive Combo-Multiplikator und einem typabhängigen Multiplikator
## (z. B. höher bei Gold-Männchen). Gibt die erzielten Punkte zurück.
## Erhöht auch die Streak (F126).
func register_hit(type_multiplier: int = 1) -> int:
	if not game_active:
		return 0

	# Combo erhöhen, solange schnell hintereinander getroffen wird
	combo += 1
	_combo_timer = combo_time_window

	# Streak erhöhen für aufeinanderfolgende Treffer (F126)
	streak += 1

	# Punkte = Grundpunkte * Combo-Multiplikator * Typ-Multiplikator * Power-Up-Multiplikator (F042)
	var points: int = int(base_hit_points * combo * type_multiplier * points_multiplier)
	score += points

	# Statistiken aktualisieren (F130)
	best_combo = maxi(best_combo, combo)
	hits_total += 1
	avg_points_per_hit = float(score) / float(hits_total)

	score_changed.emit(score)
	combo_changed.emit(combo)
	streak_changed.emit(streak)
	hit_registered.emit(points)
	return points


## Gibt den höchsten gespeicherten Punktestand zurück (0, falls keiner).
func get_high_score() -> int:
	return int(highscores[0]) if highscores.size() > 0 else 0


## Trägt einen Punktestand in die Bestenliste ein und speichert.
func _record_highscore(value: int) -> void:
	if value <= 0:
		return
	highscores.append(value)
	highscores.sort()
	highscores.reverse()                       # absteigend sortieren
	if highscores.size() > MAX_HIGHSCORES:
		highscores.resize(MAX_HIGHSCORES)
	_save_game()


## Speichert den Spielstand persistent (F195).
func _save_game() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("scores", "highscores", highscores)
	cfg.save(SAVE_PATH)


## Lädt den Spielstand, falls vorhanden (F195).
func _load_game() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		highscores = cfg.get_value("scores", "highscores", [])


## Aktiviert den Combo-Schutz für duration Sekunden (F049).
## Das Combo-Zeitfenster läuft während dieser Zeit nicht ab.
func activate_combo_shield(duration: float = 3.0) -> void:
	combo_shield_active = true
	_combo_shield_timer = maxf(_combo_shield_timer, duration)


## Setzt den Spielmodus und passt die Einstellungen an (F085, F089)
func set_game_mode(mode: String) -> void:
	game_mode = mode
	match mode:
		"practice":  # Übungsmodus ohne Timer (F085)
			round_duration = 999.0
			base_hit_points = 10
		"easy":  # Einfach (F089)
			round_duration = 90.0
			base_hit_points = 15
		"hard":  # Schwer (F089)
			round_duration = 45.0
			base_hit_points = 5
		_:  # Normal
			round_duration = 60.0
			base_hit_points = 10


## Setzt die Combo zurück (z. B. wenn das Zeitfenster abläuft).
func _reset_combo() -> void:
	combo = 0
	_combo_timer = 0.0
	combo_timer_pct = 0.0
	combo_changed.emit(combo)


# --- Power-Up System (F041/F044/F052) ---

## Aktiviert ein Power-Up mit einer Dauer.
func activate_powerup(type: String, duration: float, data: Dictionary = {}) -> void:
	if type == "time_bonus":
		time_left += duration * 5.0  # +5 Sekunden pro Pickup (F041)
	elif type == "big_projectile":
		projectile_scale_bonus = 1.5  # Geschoss 1.5x größer (F044)
	elif type == "points_double":
		points_multiplier = 2.0  # Punkte verdoppelt (F042)
	elif type == "multi_shot":
		multi_shot_count = 3  # 3 Geschosse auf einmal (F043)
	active_powerups[type] = {"duration": duration, "data": data}


## Deaktiviert ein Power-Up.
func _deactivate_powerup(type: String) -> void:
	if type == "big_projectile":
		projectile_scale_bonus = 1.0
	elif type == "points_double":
		points_multiplier = 1.0
	elif type == "multi_shot":
		multi_shot_count = 1
	active_powerups.erase(type)


## Gibt Dauer/Status eines aktiven Power-Ups zurück (für HUD, F055).
func get_powerup_remaining(type: String) -> float:
	if type in active_powerups:
		return active_powerups[type]["duration"]
	return 0.0
