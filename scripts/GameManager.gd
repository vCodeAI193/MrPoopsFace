extends Node
## GameManager (Autoload)
## Verwaltet den globalen Spielzustand: Punktestand, Combo und Rundentimer.
## Wird in der Projektkonfiguration als Singleton "GameManager" registriert.

# --- Signale, über die sich die HUD und andere Knoten benachrichtigen lassen ---
signal score_changed(new_score: int)          ## Wird bei Punkteänderung gesendet
signal combo_changed(new_combo: int)           ## Wird bei Combo-Änderung gesendet
signal time_changed(seconds_left: float)       ## Wird jede Sekunde aktualisiert
signal game_over(final_score: int)             ## Wird beim Rundenende gesendet
signal game_started()                          ## Wird beim Rundenstart gesendet

# --- Einstellbare Werte (im Inspector / per Code anpassbar) ---
@export var round_duration: float = 60.0       ## Rundenlänge in Sekunden
@export var combo_time_window: float = 1.5     ## Zeitfenster für aufeinanderfolgende Treffer
@export var base_hit_points: int = 10          ## Grundpunkte pro Treffer

# --- Laufzeit-Status ---
var score: int = 0
var combo: int = 0
var time_left: float = 0.0
var game_active: bool = false

var _combo_timer: float = 0.0                  ## Restzeit, in der die Combo gültig bleibt


func _process(delta: float) -> void:
	if not game_active:
		return

	# Rundentimer herunterzählen
	time_left -= delta
	time_changed.emit(time_left)

	# Combo-Fenster herunterzählen; läuft es ab, wird die Combo zurückgesetzt
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_reset_combo()

	# Runde beenden, wenn die Zeit abgelaufen ist
	if time_left <= 0.0:
		time_left = 0.0
		end_game()


## Startet eine neue Runde und setzt alle Werte zurück.
func start_game() -> void:
	score = 0
	combo = 0
	_combo_timer = 0.0
	time_left = round_duration
	game_active = true
	score_changed.emit(score)
	combo_changed.emit(combo)
	time_changed.emit(time_left)
	game_started.emit()


## Beendet die laufende Runde und meldet den Endpunktestand.
func end_game() -> void:
	if not game_active:
		return
	game_active = false
	game_over.emit(score)


## Registriert einen Treffer auf ein Strichmännchen und berechnet die Punkte
## inklusive Combo-Multiplikator.
func register_hit() -> void:
	if not game_active:
		return

	# Combo erhöhen, solange schnell hintereinander getroffen wird
	combo += 1
	_combo_timer = combo_time_window

	# Punkte = Grundpunkte * Combo-Multiplikator
	var points: int = base_hit_points * combo
	score += points

	score_changed.emit(score)
	combo_changed.emit(combo)


## Setzt die Combo zurück (z. B. wenn das Zeitfenster abläuft).
func _reset_combo() -> void:
	combo = 0
	_combo_timer = 0.0
	combo_changed.emit(combo)
