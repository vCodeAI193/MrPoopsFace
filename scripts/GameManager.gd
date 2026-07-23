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
signal powerup_activated(type: String)         ## Wird beim Einsammeln eines Power-Ups gesendet (F123)
signal ammo_changed(ammo_left: int)            ## Wird bei Munitionsänderung gesendet (F004)
signal misses_changed(new_misses: int)         ## Wird bei Fehlwurf gesendet (F077/F083)
signal combo_broken_by_miss(lost_combo: int)   ## Fehlwurf hat eine Combo >= 3 gebrochen

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

# --- Spielstatistiken (F130) ---
var best_combo: int = 0               ## Beste Combo in dieser Runde
var hits_total: int = 0               ## Gesamtzahl Treffer
var avg_points_per_hit: float = 0.0   ## Durchschnitt Punkte/Treffer

# --- Sterne-Bewertung pro Runde (F105) ---
## Schwellen für 1/2/3 Sterne; combo_hunt wertet die Combo statt Punkte
const STAR_THRESHOLDS: Dictionary = {
	"normal": [500, 1500, 3000],
	"easy": [500, 1500, 3000],
	"hard": [300, 900, 1800],
	"endless": [500, 1500, 3000],
	"survival": [500, 1500, 3000],
	"combo_hunt": [5, 10, 15],
}
var last_stars: int = 0               ## Sterne der letzten Runde (0–3)

var _combo_timer: float = 0.0                  ## Restzeit, in der die Combo gültig bleibt
var combo_timer_pct: float = 0.0              ## Verhältnis 0..1 für den Fortschrittsbalken (F119)
var combo_shield_active: bool = false         ## Läuft der Combo-Schutz gerade? (F049)
var _combo_shield_timer: float = 0.0

# --- Power-Up System (F041/F042/F043/F044/F052) ---
var active_powerups: Dictionary = {}          ## Aktive Power-Ups: {"type": {duration: float, data: {...}}}
var projectile_scale_bonus: float = 1.0       ## Geschoss-Größen-Multiplikator (F044)
var points_multiplier: float = 1.0             ## Punkte-Multiplikator (F042)
var multi_shot_count: int = 1                 ## Anzahl Geschosse pro Wurf (F043)

# --- Umgebung & erweiterte Power-Ups ---
var wind_force: Vector2 = Vector2.ZERO        ## Seitliche Windkraft (F007)
var freeze_active: bool = false               ## Alle Männchen eingefroren (F045)
var magnet_active: bool = false               ## Magnet-Power-Up aktiv (F047)
var bomb_shield_active: bool = false          ## Schutz vor Bomben-Strafe aktiv (F048)

# --- Munition (F004) ---
var ammo_per_round: int = -1                  ## Würfe pro Runde; -1 = unbegrenzt
var ammo_left: int = -1                       ## Verbleibende Würfe in dieser Runde

# --- Fehlwürfe (F077/F083) ---
var miss_limit: int = -1                      ## Erlaubte Fehlwürfe; -1 = unbegrenzt
var misses: int = 0                           ## Fehlwürfe in dieser Runde

# --- Game Modes & Einstellungen ---
## "normal", "practice" (F085), "easy"/"hard" (F089),
## "endless"/"survival"/"combo_hunt"/"zen" (F077/F083/F092/F093)
var game_mode: String = "normal"

# --- Optionen (F179, F137, F181, F183, F166) ---
var music_volume: float = 0.7                  ## Musiklautstärke 0..1 (F137)
var sfx_volume: float = 1.0                    ## Effektlautstärke 0..1 (F137)
var screen_shake_enabled: bool = true          ## Bildschirm-Erschütterung an/aus (F181)
var reduced_motion: bool = false               ## Reduzierte Bewegung (F183)
var vibration_strength: float = 1.0            ## Vibrationsstärke 0..1 (F166)
var tutorial_seen: bool = false                ## Erst-Start-Tutorial schon gezeigt? (F162)

var _music_player: AudioStreamPlayer           ## Spielt den Hintergrund-Loop (F134)


func _ready() -> void:
	_setup_audio_buses()
	_load_game()
	apply_audio_settings()
	_start_music()


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
	# Modi ohne Timer (F085/F077/F083/F093): extrem lange Zeit (praktisch unbegrenzt)
	var timerless_modes: Array = ["practice", "endless", "survival", "zen"]
	time_left = 3600.0 if game_mode in timerless_modes else round_duration
	game_active = true
	# Statistiken zurücksetzen (F130)
	best_combo = 0
	hits_total = 0
	avg_points_per_hit = 0.0
	wind_force = Vector2(randf_range(-120.0, 120.0), 0.0)  # Wind randomisieren (F007)
	freeze_active = false
	magnet_active = false
	bomb_shield_active = false
	projectile_scale_bonus = 1.0
	points_multiplier = 1.0
	multi_shot_count = 1
	active_powerups.clear()
	# Munition auffüllen (F004)
	ammo_left = ammo_per_round
	ammo_changed.emit(ammo_left)
	# Fehlwürfe zurücksetzen (F077/F083)
	misses = 0
	misses_changed.emit(misses)
	score_changed.emit(score)
	combo_changed.emit(combo)
	streak_changed.emit(streak)
	time_changed.emit(time_left)
	game_started.emit()


## Beendet die laufende Runde und meldet den Endpunktestand.
## Highscores werden nur in wertenden Modi eingetragen (F092/F093).
func end_game() -> void:
	if not game_active:
		return
	game_active = false
	var scoring_modes: Array = ["normal", "easy", "hard", "endless", "survival"]
	if game_mode in scoring_modes:
		# Prüfen, ob es ein neuer Rekord ist, bevor der Score eingetragen wird
		last_was_highscore = score > 0 and (highscores.is_empty() or score > int(highscores[0]))
		_record_highscore(score)
	else:
		last_was_highscore = false
	# Sterne-Bewertung berechnen (F105)
	last_stars = _compute_stars()
	game_over.emit(score)


## Berechnet 0–3 Sterne für die abgelaufene Runde (F105).
func _compute_stars() -> int:
	if game_mode not in STAR_THRESHOLDS:
		return 0
	var thresholds: Array = STAR_THRESHOLDS[game_mode]
	var stars: int = 0
	for t in thresholds:
		if score >= int(t):
			stars += 1
	return stars


## Liefert die Schwelle für den nächsten Stern, oder -1 bei 3 Sternen (F105).
func next_star_goal() -> int:
	if game_mode not in STAR_THRESHOLDS or last_stars >= 3:
		return -1
	return int(STAR_THRESHOLDS[game_mode][last_stars])


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
	if game_mode == "combo_hunt":
		# Combo-Jagd (F092): Die Punkteanzeige führt die höchste erreichte Combo
		score = maxi(score, combo)
	else:
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


## Zieht Punkte für ein Bomben-Männchen ab (F029).
## Mit aktivem Bomben-Schutz (F048) entfällt die Strafe.
func register_bomb_hit(penalty: int = 50) -> void:
	if not game_active or bomb_shield_active:
		return
	score = maxi(0, score - penalty)
	score_changed.emit(score)


## Verbraucht einen Wurf Munition; gibt false zurück, wenn keine mehr da ist (F004).
func consume_ammo() -> bool:
	if ammo_left < 0:
		return true                              # -1 = unbegrenzt
	if ammo_left == 0:
		return false
	ammo_left -= 1
	ammo_changed.emit(ammo_left)
	return true


## Füllt Munition nach (z. B. als Belohnung für Treffer, F004).
func add_ammo(amount: int) -> void:
	if ammo_left < 0:
		return
	ammo_left += amount
	ammo_changed.emit(ammo_left)


## Registriert einen Fehlwurf (F077/F083).
## Bricht in allen wertenden Modi die Combo und Streak (Risk/Reward:
## Präzision lohnt sich, Spammen kostet). Beendet die Runde, wenn das
## Fehlwurf-Limit des Modus erreicht ist.
func register_miss() -> void:
	if not game_active:
		return
	# Combo & Streak brechen (außer im entspannten Zen-Modus)
	if game_mode != "zen":
		if combo >= 3:
			combo_broken_by_miss.emit(combo)
		if combo > 0:
			_reset_combo()
		if streak > 0:
			streak = 0
			streak_changed.emit(streak)
	# Fehlwurf-Limit nur in Modi, die eines haben
	if miss_limit < 0:
		return
	misses += 1
	misses_changed.emit(misses)
	if misses >= miss_limit:
		end_game()


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


## Speichert den Spielstand persistent (F195), inkl. Optionen (F179).
func _save_game() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("scores", "highscores", highscores)
	cfg.set_value("settings", "music_volume", music_volume)
	cfg.set_value("settings", "sfx_volume", sfx_volume)
	cfg.set_value("settings", "screen_shake_enabled", screen_shake_enabled)
	cfg.set_value("settings", "reduced_motion", reduced_motion)
	cfg.set_value("settings", "vibration_strength", vibration_strength)
	cfg.set_value("settings", "tutorial_seen", tutorial_seen)
	cfg.save(SAVE_PATH)


## Lädt den Spielstand, falls vorhanden (F195), inkl. Optionen (F179).
func _load_game() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		highscores = cfg.get_value("scores", "highscores", [])
		music_volume = cfg.get_value("settings", "music_volume", 0.7)
		sfx_volume = cfg.get_value("settings", "sfx_volume", 1.0)
		screen_shake_enabled = cfg.get_value("settings", "screen_shake_enabled", true)
		reduced_motion = cfg.get_value("settings", "reduced_motion", false)
		vibration_strength = cfg.get_value("settings", "vibration_strength", 1.0)
		tutorial_seen = cfg.get_value("settings", "tutorial_seen", false)


# --- Audio-Setup & Optionen (F134, F137, F142, F179, F187) ---

## Legt die Audio-Busse "Music" und "SFX" an, mit leichtem Hall auf SFX (F142).
func _setup_audio_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx: int = AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
	# Leichter Raumhall auf den Effekten (F142)
	var sfx_idx: int = AudioServer.get_bus_index("SFX")
	if AudioServer.get_bus_effect_count(sfx_idx) == 0:
		var reverb: AudioEffectReverb = AudioEffectReverb.new()
		reverb.wet = 0.12
		reverb.room_size = 0.4
		AudioServer.add_bus_effect(sfx_idx, reverb)


## Überträgt die Lautstärke-Einstellungen auf die Audio-Busse (F137).
func apply_audio_settings() -> void:
	var music_idx: int = AudioServer.get_bus_index("Music")
	var sfx_idx: int = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(music_idx, linear_to_db(maxf(music_volume, 0.001)))
	AudioServer.set_bus_mute(music_idx, music_volume <= 0.0)
	AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(maxf(sfx_volume, 0.001)))
	AudioServer.set_bus_mute(sfx_idx, sfx_volume <= 0.0)


## Startet den prozeduralen Hintergrundmusik-Loop (F134).
## Läuft auch während der Pause weiter.
func _start_music() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player.stream = SoundGen.music_loop()
	add_child(_music_player)
	_music_player.play()


## Speichert die aktuellen Optionen (F179).
func save_settings() -> void:
	_save_game()


## Merkt sich, dass das Erst-Start-Tutorial gezeigt wurde (F162).
func mark_tutorial_seen() -> void:
	tutorial_seen = true
	_save_game()


## Setzt alle Optionen auf die Standardwerte zurück (F187).
func reset_settings() -> void:
	music_volume = 0.7
	sfx_volume = 1.0
	screen_shake_enabled = true
	reduced_motion = false
	vibration_strength = 1.0
	apply_audio_settings()
	_save_game()


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
			ammo_per_round = -1
			miss_limit = -1
		"easy":  # Einfach (F089)
			round_duration = 90.0
			base_hit_points = 15
			ammo_per_round = -1
			miss_limit = -1
		"hard":  # Schwer (F089): begrenzte Munition (F004)
			round_duration = 45.0
			base_hit_points = 5
			ammo_per_round = 30
			miss_limit = -1
		"endless":  # Endlos ohne Timer, 3 Fehlwürfe = Ende (F077)
			round_duration = 999.0
			base_hit_points = 10
			ammo_per_round = -1
			miss_limit = 3
		"survival":  # Überleben mit Wellen, 5 Fehlwürfe = Ende (F083)
			round_duration = 999.0
			base_hit_points = 10
			ammo_per_round = -1
			miss_limit = 5
		"combo_hunt":  # Combo-Jagd: höchste Combo zählt (F092)
			round_duration = 60.0
			base_hit_points = 10
			ammo_per_round = -1
			miss_limit = -1
		"zen":  # Zen: entspannt, keine Wertung, kein Ende (F093)
			round_duration = 999.0
			base_hit_points = 10
			ammo_per_round = -1
			miss_limit = -1
		_:  # Normal
			round_duration = 60.0
			base_hit_points = 10
			ammo_per_round = -1
			miss_limit = -1


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
	elif type == "freeze":
		freeze_active = true  # Alle Männchen einfrieren (F045)
	elif type == "magnet":
		magnet_active = true  # Geschosse ziehen zu Männchen (F047)
	elif type == "bomb_shield":
		bomb_shield_active = true  # Schutz vor Bomben-Strafe (F048)
	active_powerups[type] = {"duration": duration, "data": data}
	powerup_activated.emit(type)


## Deaktiviert ein Power-Up.
func _deactivate_powerup(type: String) -> void:
	if type == "big_projectile":
		projectile_scale_bonus = 1.0
	elif type == "points_double":
		points_multiplier = 1.0
	elif type == "multi_shot":
		multi_shot_count = 1
	elif type == "freeze":
		freeze_active = false
	elif type == "magnet":
		magnet_active = false
	elif type == "bomb_shield":
		bomb_shield_active = false
	active_powerups.erase(type)


## Gibt Dauer/Status eines aktiven Power-Ups zurück (für HUD, F055).
func get_powerup_remaining(type: String) -> float:
	if type in active_powerups:
		return active_powerups[type]["duration"]
	return 0.0
