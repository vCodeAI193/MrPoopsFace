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

var _combo_timer: float = 0.0                  ## Restzeit, in der die Combo gültig bleibt
var combo_timer_pct: float = 0.0              ## Verhältnis 0..1 für den Fortschrittsbalken (F119)
var combo_shield_active: bool = false         ## Läuft der Combo-Schutz gerade? (F049)
var _combo_shield_timer: float = 0.0


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
	time_left = round_duration
	game_active = true
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

	# Punkte = Grundpunkte * Combo-Multiplikator * Typ-Multiplikator
	var points: int = base_hit_points * combo * type_multiplier
	score += points

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


## Setzt die Combo zurück (z. B. wenn das Zeitfenster abläuft).
func _reset_combo() -> void:
	combo = 0
	_combo_timer = 0.0
	combo_timer_pct = 0.0
	combo_changed.emit(combo)
